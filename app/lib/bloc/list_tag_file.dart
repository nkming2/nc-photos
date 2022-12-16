import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/find_file.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'list_tag_file.g.dart';

abstract class ListTagFileBlocEvent {
  const ListTagFileBlocEvent();
}

@toString
class ListTagFileBlocQuery extends ListTagFileBlocEvent {
  const ListTagFileBlocQuery(this.account, this.tag);

  @override
  String toString() => _$toString();

  final Account account;
  final Tag tag;
}

/// An external event has happened and may affect the state of this bloc
@toString
class _ListTagFileBlocExternalEvent extends ListTagFileBlocEvent {
  const _ListTagFileBlocExternalEvent();

  @override
  String toString() => _$toString();
}

@toString
abstract class ListTagFileBlocState {
  const ListTagFileBlocState(this.account, this.items);

  @override
  String toString() => _$toString();

  final Account? account;
  final List<File> items;
}

class ListTagFileBlocInit extends ListTagFileBlocState {
  ListTagFileBlocInit() : super(null, const []);
}

class ListTagFileBlocLoading extends ListTagFileBlocState {
  const ListTagFileBlocLoading(Account? account, List<File> items)
      : super(account, items);
}

class ListTagFileBlocSuccess extends ListTagFileBlocState {
  const ListTagFileBlocSuccess(Account? account, List<File> items)
      : super(account, items);
}

@toString
class ListTagFileBlocFailure extends ListTagFileBlocState {
  const ListTagFileBlocFailure(
      Account? account, List<File> items, this.exception)
      : super(account, items);

  @override
  String toString() => _$toString();

  final Object exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ListTagFileBlocInconsistent extends ListTagFileBlocState {
  const ListTagFileBlocInconsistent(Account? account, List<File> items)
      : super(account, items);
}

/// List all files associated with a specific tag
@npLog
class ListTagFileBloc extends Bloc<ListTagFileBlocEvent, ListTagFileBlocState> {
  ListTagFileBloc(this._c)
      : assert(require(_c)),
        // assert(PopulatePerson.require(_c)),
        super(ListTagFileBlocInit()) {
    _fileRemovedEventListener.begin();
    _filePropertyUpdatedEventListener.begin();

    on<ListTagFileBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.taggedFileRepo);

  @override
  close() {
    _fileRemovedEventListener.end();
    _filePropertyUpdatedEventListener.end();
    return super.close();
  }

  Future<void> _onEvent(
      ListTagFileBlocEvent event, Emitter<ListTagFileBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListTagFileBlocQuery) {
      await _onEventQuery(event, emit);
    } else if (event is _ListTagFileBlocExternalEvent) {
      await _onExternalEvent(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListTagFileBlocQuery ev, Emitter<ListTagFileBlocState> emit) async {
    try {
      emit(ListTagFileBlocLoading(ev.account, state.items));
      emit(ListTagFileBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListTagFileBlocFailure(ev.account, state.items, e));
    }
  }

  Future<void> _onExternalEvent(_ListTagFileBlocExternalEvent ev,
      Emitter<ListTagFileBlocState> emit) async {
    emit(ListTagFileBlocInconsistent(state.account, state.items));
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ListTagFileBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (_isFileOfInterest(ev.file)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  void _onFilePropertyUpdatedEvent(FilePropertyUpdatedEvent ev) {
    if (!ev.hasAnyProperties([
      FilePropertyUpdatedEvent.propMetadata,
      FilePropertyUpdatedEvent.propIsArchived,
      FilePropertyUpdatedEvent.propOverrideDateTime,
      FilePropertyUpdatedEvent.propFavorite,
    ])) {
      // not interested
      return;
    }
    if (state is ListTagFileBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (!_isFileOfInterest(ev.file)) {
      return;
    }

    if (ev.hasAnyProperties([
      FilePropertyUpdatedEvent.propIsArchived,
      FilePropertyUpdatedEvent.propOverrideDateTime,
      FilePropertyUpdatedEvent.propFavorite,
    ])) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    } else {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 10),
        maxPendingCount: 10,
      );
    }
  }

  Future<List<File>> _query(ListTagFileBlocQuery ev) async {
    final files = <File>[];
    for (final r in ev.account.roots) {
      final dir = File(path: file_util.unstripPath(ev.account, r));
      final taggedFiles =
          await _c.taggedFileRepo.list(ev.account, dir, [ev.tag]);
      files.addAll(await FindFile(_c)(
        ev.account,
        taggedFiles.map((e) => e.fileId).toList(),
        onFileNotFound: (id) {
          _log.warning("[_query] Missing file: $id");
        },
      ));
    }
    return files.where((f) => file_util.isSupportedFormat(f)).toList();
  }

  bool _isFileOfInterest(File file) {
    if (!file_util.isSupportedFormat(file)) {
      return false;
    }

    for (final r in state.account?.roots ?? []) {
      final dir = File(path: file_util.unstripPath(state.account!, r));
      if (file_util.isUnderDir(file, dir)) {
        return true;
      }
    }
    return false;
  }

  final DiContainer _c;

  late final _fileRemovedEventListener =
      AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
  late final _filePropertyUpdatedEventListener =
      AppEventListener<FilePropertyUpdatedEvent>(_onFilePropertyUpdatedEvent);

  late final _refreshThrottler = Throttler(
    onTriggered: (_) {
      add(const _ListTagFileBlocExternalEvent());
    },
    logTag: "ListTagFileBloc.refresh",
  );
}
