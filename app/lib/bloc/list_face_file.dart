import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/populate_person.dart';
import 'package:to_string/to_string.dart';

part 'list_face_file.g.dart';

abstract class ListFaceFileBlocEvent {
  const ListFaceFileBlocEvent();
}

@toString
class ListFaceFileBlocQuery extends ListFaceFileBlocEvent {
  const ListFaceFileBlocQuery(this.account, this.person);

  @override
  String toString() => _$toString();

  final Account account;
  final Person person;
}

/// An external event has happened and may affect the state of this bloc
@toString
class _ListFaceFileBlocExternalEvent extends ListFaceFileBlocEvent {
  const _ListFaceFileBlocExternalEvent();

  @override
  String toString() => _$toString();
}

@toString
abstract class ListFaceFileBlocState {
  const ListFaceFileBlocState(this.account, this.items);

  @override
  String toString() => _$toString();

  final Account? account;
  final List<File> items;
}

class ListFaceFileBlocInit extends ListFaceFileBlocState {
  ListFaceFileBlocInit() : super(null, const []);
}

class ListFaceFileBlocLoading extends ListFaceFileBlocState {
  const ListFaceFileBlocLoading(Account? account, List<File> items)
      : super(account, items);
}

class ListFaceFileBlocSuccess extends ListFaceFileBlocState {
  const ListFaceFileBlocSuccess(Account? account, List<File> items)
      : super(account, items);
}

@toString
class ListFaceFileBlocFailure extends ListFaceFileBlocState {
  const ListFaceFileBlocFailure(
      Account? account, List<File> items, this.exception)
      : super(account, items);

  @override
  String toString() => _$toString();

  final Object exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ListFaceFileBlocInconsistent extends ListFaceFileBlocState {
  const ListFaceFileBlocInconsistent(Account? account, List<File> items)
      : super(account, items);
}

/// List all people recognized in an account
class ListFaceFileBloc
    extends Bloc<ListFaceFileBlocEvent, ListFaceFileBlocState> {
  ListFaceFileBloc(this._c)
      : assert(require(_c)),
        assert(PopulatePerson.require(_c)),
        super(ListFaceFileBlocInit()) {
    _fileRemovedEventListener.begin();
    _filePropertyUpdatedEventListener.begin();

    on<ListFaceFileBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) => DiContainer.has(c, DiType.faceRepo);

  @override
  close() {
    _fileRemovedEventListener.end();
    _filePropertyUpdatedEventListener.end();
    return super.close();
  }

  Future<void> _onEvent(
      ListFaceFileBlocEvent event, Emitter<ListFaceFileBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListFaceFileBlocQuery) {
      await _onEventQuery(event, emit);
    } else if (event is _ListFaceFileBlocExternalEvent) {
      await _onExternalEvent(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListFaceFileBlocQuery ev, Emitter<ListFaceFileBlocState> emit) async {
    try {
      emit(ListFaceFileBlocLoading(ev.account, state.items));
      emit(ListFaceFileBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListFaceFileBlocFailure(ev.account, state.items, e));
    }
  }

  Future<void> _onExternalEvent(_ListFaceFileBlocExternalEvent ev,
      Emitter<ListFaceFileBlocState> emit) async {
    emit(ListFaceFileBlocInconsistent(state.account, state.items));
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ListFaceFileBlocInit) {
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
    if (state is ListFaceFileBlocInit) {
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

  Future<List<File>> _query(ListFaceFileBlocQuery ev) async {
    final faces = await _c.faceRepo.list(ev.account, ev.person);
    final files = await PopulatePerson(_c)(ev.account, faces);
    final rootDirs = ev.account.roots
        .map((e) => File(path: file_util.unstripPath(ev.account, e)))
        .toList();
    return files
        .where((f) =>
            file_util.isSupportedFormat(f) &&
            rootDirs.any((dir) => file_util.isUnderDir(f, dir)))
        .toList();
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
      add(const _ListFaceFileBlocExternalEvent());
    },
    logTag: "ListFaceFileBloc.refresh",
  );

  static final _log = Logger("bloc.list_face_file.ListFaceFileBloc");
}
