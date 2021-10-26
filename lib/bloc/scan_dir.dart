import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/scan_dir.dart';

abstract class ScanDirBlocEvent {
  const ScanDirBlocEvent();
}

class ScanDirBlocQueryBase extends ScanDirBlocEvent with EquatableMixin {
  const ScanDirBlocQueryBase(this.account, this.roots);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "roots: ${roots.map((e) => e.path).toReadableString()}, "
        "}";
  }

  @override
  get props => [
        account,
        roots,
      ];

  final Account account;
  final List<File> roots;
}

class ScanDirBlocQuery extends ScanDirBlocQueryBase {
  const ScanDirBlocQuery(Account account, List<File> roots)
      : super(account, roots);
}

class ScanDirBlocRefresh extends ScanDirBlocQueryBase {
  const ScanDirBlocRefresh(Account account, List<File> roots)
      : super(account, roots);
}

/// An external event has happened and may affect the state of this bloc
class _ScanDirBlocExternalEvent extends ScanDirBlocEvent {
  const _ScanDirBlocExternalEvent();

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }
}

abstract class ScanDirBlocState {
  const ScanDirBlocState(this.account, this.files);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "files: List {length: ${files.length}}, "
        "}";
  }

  final Account? account;
  final List<File> files;
}

class ScanDirBlocInit extends ScanDirBlocState {
  const ScanDirBlocInit() : super(null, const []);
}

class ScanDirBlocLoading extends ScanDirBlocState {
  const ScanDirBlocLoading(Account? account, List<File> files)
      : super(account, files);
}

class ScanDirBlocSuccess extends ScanDirBlocState {
  const ScanDirBlocSuccess(Account? account, List<File> files)
      : super(account, files);
}

class ScanDirBlocFailure extends ScanDirBlocState {
  const ScanDirBlocFailure(Account? account, List<File> files, this.exception)
      : super(account, files);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ScanDirBlocInconsistent extends ScanDirBlocState {
  const ScanDirBlocInconsistent(Account? account, List<File> files)
      : super(account, files);
}

/// A bloc that return all files under a dir recursively
///
/// See [ScanDir]
class ScanDirBloc extends Bloc<ScanDirBlocEvent, ScanDirBlocState> {
  ScanDirBloc() : super(const ScanDirBlocInit()) {
    _fileRemovedEventListener =
        AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
    _filePropertyUpdatedEventListener =
        AppEventListener<FilePropertyUpdatedEvent>(_onFilePropertyUpdatedEvent);
    _fileTrashbinRestoredEventListener =
        AppEventListener<FileTrashbinRestoredEvent>(
            _onFileTrashbinRestoredEvent);
    _fileRemovedEventListener.begin();
    _filePropertyUpdatedEventListener.begin();
    _fileTrashbinRestoredEventListener.begin();
    _fileMovedEventListener.begin();

    _refreshThrottler = Throttler(
      onTriggered: (_) {
        add(const _ScanDirBlocExternalEvent());
      },
      logTag: "ScanDirBloc.refresh",
    );
  }

  static ScanDirBloc of(Account account) {
    final id =
        "${account.scheme}://${account.username}@${account.address}?${account.roots.join('&')}";
    try {
      _log.fine("[of] Resolving bloc for '$id'");
      return KiwiContainer().resolve<ScanDirBloc>("ScanDirBloc($id)");
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ScanDirBloc();
      KiwiContainer()
          .registerInstance<ScanDirBloc>(bloc, name: "ScanDirBloc($id)");
      return bloc;
    }
  }

  @override
  transformEvents(Stream<ScanDirBlocEvent> events, transitionFn) {
    return super.transformEvents(events.distinct((a, b) {
      // only handle ScanDirBlocQuery
      final r = a is ScanDirBlocQuery && b is ScanDirBlocQuery && a == b;
      if (r) {
        _log.fine("[transformEvents] Skip identical ScanDirBlocQuery event");
      }
      return r;
    }), transitionFn);
  }

  @override
  mapEventToState(ScanDirBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ScanDirBlocQueryBase) {
      yield* _onEventQuery(event);
    } else if (event is _ScanDirBlocExternalEvent) {
      yield* _onExternalEvent(event);
    }
  }

  @override
  close() {
    _fileRemovedEventListener.end();
    _filePropertyUpdatedEventListener.end();
    _fileTrashbinRestoredEventListener.end();
    _refreshThrottler.clear();
    return super.close();
  }

  Stream<ScanDirBlocState> _onEventQuery(ScanDirBlocQueryBase ev) async* {
    yield ScanDirBlocLoading(ev.account, state.files);
    bool hasContent = state.files.isNotEmpty;

    if (!hasContent) {
      // show something instantly on first load
      ScanDirBlocState cacheState = const ScanDirBlocInit();
      await for (final s in _queryOffline(ev, () => cacheState)) {
        cacheState = s;
      }
      yield ScanDirBlocLoading(ev.account, cacheState.files);
      hasContent = cacheState.files.isNotEmpty;
    }

    ScanDirBlocState newState = const ScanDirBlocInit();
    if (!hasContent) {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
        yield s;
      }
    } else {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
      }
      if (newState is ScanDirBlocSuccess) {
        yield newState;
      } else if (newState is ScanDirBlocFailure) {
        yield ScanDirBlocFailure(ev.account, state.files, newState.exception);
      }
    }
  }

  Stream<ScanDirBlocState> _onExternalEvent(
      _ScanDirBlocExternalEvent ev) async* {
    yield ScanDirBlocInconsistent(state.account, state.files);
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ScanDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (!file_util.isTrash(ev.account, ev.file)) {
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
    ])) {
      // not interested
      return;
    }
    if (state is ScanDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }

    if (ev.hasAnyProperties([
      FilePropertyUpdatedEvent.propIsArchived,
      FilePropertyUpdatedEvent.propOverrideDateTime,
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

  void _onFileTrashbinRestoredEvent(FileTrashbinRestoredEvent ev) {
    if (state is ScanDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  void _onFileMovedEvent(FileMovedEvent ev) {
    if (state is ScanDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (file_util.isSupportedFormat(ev.file)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  Stream<ScanDirBlocState> _queryOffline(
          ScanDirBlocQueryBase ev, ScanDirBlocState Function() getState) =>
      _queryWithFileDataSource(ev, getState, FileAppDbDataSource());

  Stream<ScanDirBlocState> _queryOnline(
      ScanDirBlocQueryBase ev, ScanDirBlocState Function() getState) {
    final stream = _queryWithFileDataSource(ev, getState,
        FileCachedDataSource(shouldCheckCache: _shouldCheckCache));
    _shouldCheckCache = false;
    return stream;
  }

  Stream<ScanDirBlocState> _queryWithFileDataSource(ScanDirBlocQueryBase ev,
      ScanDirBlocState Function() getState, FileDataSource dataSrc) async* {
    try {
      for (final r in ev.roots) {
        final dataStream = ScanDir(FileRepo(dataSrc))(ev.account, r);
        await for (final d in dataStream) {
          if (d is ExceptionEvent) {
            throw d.error;
          }
          yield ScanDirBlocLoading(ev.account, getState().files + d);
        }
      }
      yield ScanDirBlocSuccess(ev.account, getState().files);
    } catch (e) {
      _log.severe("[_queryWithFileDataSource] Exception while request", e);
      yield ScanDirBlocFailure(ev.account, getState().files, e);
    }
  }

  late AppEventListener<FileRemovedEvent> _fileRemovedEventListener;
  late AppEventListener<FilePropertyUpdatedEvent>
      _filePropertyUpdatedEventListener;
  late final AppEventListener<FileTrashbinRestoredEvent>
      _fileTrashbinRestoredEventListener;
  late final _fileMovedEventListener =
      AppEventListener<FileMovedEvent>(_onFileMovedEvent);

  late Throttler _refreshThrottler;

  bool _shouldCheckCache = true;

  static final _log = Logger("bloc.scan_dir.ScanDirBloc");
}
