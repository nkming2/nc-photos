import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection/builder.dart';
import 'package:nc_photos/entity/collection/content_provider/album.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/album_item_adapter.dart';
import 'package:nc_photos/entity/collection_item/new_item.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/use_case/album/add_file_to_album.dart';
import 'package:nc_photos/use_case/album/edit_album.dart';
import 'package:nc_photos/use_case/album/remove_album.dart';
import 'package:nc_photos/use_case/album/remove_from_album.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';
import 'package:tuple/tuple.dart';

part 'album.g.dart';

@npLog
class CollectionAlbumAdapter implements CollectionAdapter {
  CollectionAlbumAdapter(this._c, this.account, this.collection)
      : assert(require(_c)),
        _provider = collection.contentProvider as CollectionAlbumProvider;

  static bool require(DiContainer c) => PreProcessAlbum.require(c);

  @override
  Stream<List<CollectionItem>> listItem() async* {
    final items = await PreProcessAlbum(_c)(account, _provider.album);
    yield items.map<CollectionItem>((i) {
      if (i is AlbumFileItem) {
        return CollectionFileItemAlbumAdapter(i);
      } else if (i is AlbumLabelItem) {
        return CollectionLabelItemAlbumAdapter(i);
      } else {
        _log.shout("[listItem] Unknown item type: ${i.runtimeType}");
        throw UnimplementedError("Unknown item type: ${i.runtimeType}");
      }
    }).toList();
  }

  @override
  Future<int> addFiles(
    List<FileDescriptor> files, {
    ErrorWithValueHandler<FileDescriptor>? onError,
    required ValueChanged<Collection> onCollectionUpdated,
  }) async {
    try {
      final newAlbum =
          await AddFileToAlbum(_c)(account, _provider.album, files);
      onCollectionUpdated(CollectionBuilder.byAlbum(account, newAlbum));
      return files.length;
    } catch (e, stackTrace) {
      for (final f in files) {
        onError?.call(f, e, stackTrace);
      }
      return 0;
    }
  }

  @override
  Future<Collection> edit({
    String? name,
    List<CollectionItem>? items,
    CollectionItemSort? itemSort,
  }) async {
    assert(name != null || items != null || itemSort != null);
    final newItems = items?.run((items) => items
        .map((e) {
          if (e is AlbumAdaptedCollectionItem) {
            return e.albumItem;
          } else if (e is NewCollectionLabelItem) {
            // new labels
            return AlbumLabelItem(
              addedBy: account.userId,
              addedAt: e.createdAt,
              text: e.text,
            );
          } else {
            _log.severe("[edit] Unsupported type: ${e.runtimeType}");
            return null;
          }
        })
        .whereNotNull()
        .toList());
    final newAlbum = await EditAlbum(_c)(
      account,
      _provider.album,
      name: name,
      items: newItems,
      itemSort: itemSort,
    );
    return collection.copyWith(
      name: name,
      contentProvider: _provider.copyWith(album: newAlbum),
    );
  }

  @override
  Future<int> removeItems(
    List<CollectionItem> items, {
    ErrorWithValueIndexedHandler<CollectionItem>? onError,
    required ValueChanged<Collection> onCollectionUpdated,
  }) async {
    try {
      final group = items
          .withIndex()
          .groupListsBy((e) => e.item2 is AlbumAdaptedCollectionItem);
      var failed = 0;
      if (group[true]?.isNotEmpty ?? false) {
        final newAlbum = await RemoveFromAlbum(_c)(
          account,
          _provider.album,
          group[true]!
              .map((e) => e.item2)
              .cast<AlbumAdaptedCollectionItem>()
              .map((e) => e.albumItem)
              .toList(),
          onError: (i, item, e, stackTrace) {
            ++failed;
            final actualIndex = group[true]![i].item1;
            try {
              onError?.call(actualIndex, items[actualIndex], e, stackTrace);
            } catch (e, stackTrace) {
              _log.severe("[removeItems] Unknown error", e, stackTrace);
            }
          },
        );
        onCollectionUpdated(collection.copyWith(
          contentProvider: _provider.copyWith(
            album: newAlbum,
          ),
        ));
      }
      for (final pair in (group[false] ?? const <Tuple2<int, int>>[])) {
        final actualIndex = pair.item1;
        onError?.call(
          actualIndex,
          items[actualIndex],
          UnsupportedError(
              "Unsupported item type: ${items[actualIndex].runtimeType}"),
          StackTrace.current,
        );
      }
      return (group[true] ?? []).length - failed;
    } catch (e, stackTrace) {
      for (final pair in items.withIndex()) {
        onError?.call(pair.item1, pair.item2, e, stackTrace);
      }
      return 0;
    }
  }

  @override
  Future<CollectionItem> adaptToNewItem(NewCollectionItem original) async {
    if (original is NewCollectionFileItem) {
      final item = AlbumStaticProvider.of(_provider.album)
          .items
          .whereType<AlbumFileItem>()
          .firstWhere((e) => e.file.compareServerIdentity(original.file));
      return CollectionFileItemAlbumAdapter(item);
    } else if (original is NewCollectionLabelItem) {
      final item = AlbumStaticProvider.of(_provider.album)
          .items
          .whereType<AlbumLabelItem>()
          .sorted((a, b) => a.addedAt.compareTo(b.addedAt))
          .reversed
          .firstWhere((e) => e.text == original.text);
      return CollectionLabelItemAlbumAdapter(item);
    } else {
      throw UnsupportedError("Unsupported type: ${original.runtimeType}");
    }
  }

  @override
  bool isItemsRemovable(List<CollectionItem> items) {
    if (_provider.album.albumFile!.isOwned(account.userId)) {
      return true;
    }
    return items
        .whereType<AlbumAdaptedCollectionItem>()
        .any((e) => e.albumItem.addedBy == account.userId);
  }

  @override
  Future<void> remove() => RemoveAlbum(_c)(account, _provider.album);

  final DiContainer _c;
  final Account account;
  final Collection collection;

  final CollectionAlbumProvider _provider;
}

// class CollectionAlbumItemAdapter implements CollectionItemAdapter {}
