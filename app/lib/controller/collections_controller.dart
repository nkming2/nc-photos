import 'dart:async';

import 'package:copy_with/copy_with.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/controller/collection_items_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/rx_extension.dart';
import 'package:nc_photos/use_case/collection/create_collection.dart';
import 'package:nc_photos/use_case/collection/edit_collection.dart';
import 'package:nc_photos/use_case/collection/list_collection.dart';
import 'package:nc_photos/use_case/collection/remove_collections.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';
import 'package:rxdart/rxdart.dart';

part 'collections_controller.g.dart';

@genCopyWith
class CollectionStreamData {
  const CollectionStreamData({
    required this.collection,
    required this.controller,
  });

  final Collection collection;
  final CollectionItemsController controller;
}

@genCopyWith
class CollectionStreamEvent {
  const CollectionStreamEvent({
    required this.data,
    required this.hasNext,
  });

  CollectionItemsController itemsControllerByCollection(Collection collection) {
    final i = data.indexWhere((d) => collection.compareIdentity(d.collection));
    return data[i].controller;
  }

  final List<CollectionStreamData> data;

  /// If true, the results are intermediate values and may not represent the
  /// latest state
  final bool hasNext;
}

@npLog
class CollectionsController {
  CollectionsController(
    this._c, {
    required this.account,
  });

  void dispose() {
    _dataStreamController.close();
    for (final c in _itemControllers.values) {
      c.dispose();
    }
  }

  /// Return a stream of collections associated with [account]
  ///
  /// The returned stream will emit new list of collections whenever there are
  /// changes to the collections (e.g., new collection, removed collection, etc)
  ///
  /// There's no guarantee that the returned list is always sorted in some ways,
  /// callers must sort it by themselves if the ordering is important
  ValueStream<CollectionStreamEvent> get stream {
    if (!_isDataStreamInited) {
      _isDataStreamInited = true;
      unawaited(_load());
    }
    return _dataStreamController.stream;
  }

  /// Peek the stream and return the current value
  CollectionStreamEvent peekStream() => _dataStreamController.stream.value;

  Future<Collection> createNew(Collection collection) async {
    // we can't simply add the collection argument to the stream because
    // the collection may not be a complete workable instance
    final created = await CreateCollection(_c)(account, collection);
    _dataStreamController.addWithValue((v) => v.copyWith(
          data: _prepareDataFor([
            created,
            ...v.data.map((e) => e.collection),
          ], shouldRemoveCache: false),
        ));
    return created;
  }

  /// Remove [collections] and return the removed count
  ///
  /// If [onError] is not null, you'll get notified about the errors. The future
  /// will always complete normally
  Future<int> remove(
    List<Collection> collections, {
    ErrorWithValueHandler<Collection>? onError,
  }) async {
    final newData = _dataStreamController.value.data.toList();
    final toBeRemoved = <CollectionStreamData>[];
    var failedCount = 0;
    for (final c in collections) {
      final i = newData.indexWhere((d) => c.compareIdentity(d.collection));
      if (i == -1) {
        _log.warning("[remove] Collection not found: $c");
      } else {
        toBeRemoved.add(newData.removeAt(i));
      }
    }
    _dataStreamController.addWithValue((v) => v.copyWith(
          data: newData,
        ));

    final restore = <CollectionStreamData>[];
    await _mutex.protect(() async {
      await RemoveCollections(_c)(
        account,
        collections,
        onError: (c, e, stackTrace) {
          _log.severe(
              "[remove] Failed while RemoveCollections: $c", e, stackTrace);
          final i =
              toBeRemoved.indexWhere((d) => c.compareIdentity(d.collection));
          if (i != -1) {
            restore.add(toBeRemoved.removeAt(i));
          }
          ++failedCount;
          onError?.call(c, e, stackTrace);
        },
      );
    });
    toBeRemoved
        .map((d) => _CollectionKey(d.collection))
        .forEach(_itemControllers.remove);
    if (restore.isNotEmpty) {
      _log.severe("[remove] Restoring ${restore.length} collections");
      _dataStreamController.addWithValue((v) => v.copyWith(
            data: [
              ...restore,
              ...v.data,
            ],
          ));
    }
    return collections.length - failedCount;
  }

  /// See [EditCollection]
  Future<void> edit(
    Collection collection, {
    String? name,
    List<CollectionItem>? items,
    CollectionItemSort? itemSort,
    OrNull<FileDescriptor>? cover,
  }) async {
    try {
      final c = await _mutex.protect(() async {
        return await EditCollection(_c)(
          account,
          collection,
          name: name,
          items: items,
          itemSort: itemSort,
          cover: cover,
        );
      });
      _updateCollection(c, items);
    } catch (e, stackTrace) {
      _dataStreamController.addError(e, stackTrace);
    }
  }

  Future<void> _load() async {
    var lastData = const CollectionStreamEvent(
      data: [],
      hasNext: false,
    );
    final completer = Completer();
    ListCollection(_c)(account).listen(
      (c) {
        lastData = CollectionStreamEvent(
          data: _prepareDataFor(c, shouldRemoveCache: true),
          hasNext: true,
        );
        _dataStreamController.add(lastData);
      },
      onError: _dataStreamController.addError,
      onDone: () => completer.complete(),
    );
    await completer.future;
    _dataStreamController.add(lastData.copyWith(hasNext: false));
  }

  List<CollectionStreamData> _prepareDataFor(
    List<Collection> collections, {
    required bool shouldRemoveCache,
  }) {
    final data = <CollectionStreamData>[];
    final keys = <_CollectionKey>[];
    for (final c in collections) {
      final k = _CollectionKey(c);
      _itemControllers[k] ??= CollectionItemsController(
        _c,
        account: account,
        collection: k.collection,
        onCollectionUpdated: _updateCollection,
      );
      data.add(CollectionStreamData(
        collection: c,
        controller: _itemControllers[k]!,
      ));
      keys.add(k);
    }

    final remove =
        _itemControllers.keys.where((k) => !keys.contains(k)).toList();
    for (final k in remove) {
      _itemControllers[k]?.dispose();
      _itemControllers.remove(k);
    }

    return data;
  }

  void _updateCollection(Collection collection, [List<CollectionItem>? items]) {
    _log.info("[_updateCollection] Updating collection: $collection");
    _dataStreamController.addWithValue((v) => v.copyWith(
          data: v.data.map((d) {
            if (d.collection.compareIdentity(collection)) {
              if (items != null) {
                d.controller.forceReplaceItems(items);
              }
              return d.copyWith(collection: collection);
            } else {
              return d;
            }
          }).toList(),
        ));
  }

  final DiContainer _c;
  final Account account;

  var _isDataStreamInited = false;
  final _dataStreamController = BehaviorSubject.seeded(
    const CollectionStreamEvent(
      data: [],
      hasNext: true,
    ),
  );

  final _itemControllers = <_CollectionKey, CollectionItemsController>{};

  final _mutex = Mutex();
}

class _CollectionKey {
  const _CollectionKey(this.collection);

  @override
  bool operator ==(Object other) {
    return other is _CollectionKey &&
        collection.compareIdentity(other.collection);
  }

  @override
  int get hashCode => collection.identityHashCode;

  final Collection collection;
}
