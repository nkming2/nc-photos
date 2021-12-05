import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:nc_photos/use_case/scan_dir.dart';

abstract class ScanAccountDirBlocEvent {
  const ScanAccountDirBlocEvent();
}

class ScanAccountDirBlocQueryBase extends ScanAccountDirBlocEvent {
  const ScanAccountDirBlocQueryBase();

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }
}

class ScanAccountDirBlocQuery extends ScanAccountDirBlocQueryBase {
  const ScanAccountDirBlocQuery();
}

class ScanAccountDirBlocRefresh extends ScanAccountDirBlocQueryBase {
  const ScanAccountDirBlocRefresh();
}

/// An external event has happened and may affect the state of this bloc
class _ScanAccountDirBlocExternalEvent extends ScanAccountDirBlocEvent {
  const _ScanAccountDirBlocExternalEvent();

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }
}

abstract class ScanAccountDirBlocState {
  const ScanAccountDirBlocState(this.files);

  @override
  toString() {
    return "$runtimeType {"
        "files: List {length: ${files.length}}, "
        "}";
  }

  final List<File> files;
}

class ScanAccountDirBlocInit extends ScanAccountDirBlocState {
  const ScanAccountDirBlocInit() : super(const []);
}

class ScanAccountDirBlocLoading extends ScanAccountDirBlocState {
  const ScanAccountDirBlocLoading(List<File> files) : super(files);
}

class ScanAccountDirBlocSuccess extends ScanAccountDirBlocState {
  const ScanAccountDirBlocSuccess(List<File> files) : super(files);
}

class ScanAccountDirBlocFailure extends ScanAccountDirBlocState {
  const ScanAccountDirBlocFailure(List<File> files, this.exception)
      : super(files);

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
class ScanAccountDirBlocInconsistent extends ScanAccountDirBlocState {
  const ScanAccountDirBlocInconsistent(List<File> files) : super(files);
}

/// A bloc that return all files under a dir recursively
///
/// See [ScanDir]
class ScanAccountDirBloc
    extends Bloc<ScanAccountDirBlocEvent, ScanAccountDirBlocState> {
  ScanAccountDirBloc._(this.account) : super(const ScanAccountDirBlocInit()) {
    _fileRemovedEventListener.begin();
    _filePropertyUpdatedEventListener.begin();
    _fileTrashbinRestoredEventListener.begin();
    _fileMovedEventListener.begin();
    _prefUpdatedEventListener.begin();
    _accountPrefUpdatedEventListener.begin();
  }

  static ScanAccountDirBloc of(Account account) {
    final id =
        "${account.scheme}://${account.username}@${account.address}?${account.roots.join('&')}";
    try {
      _log.fine("[of] Resolving bloc for '$id'");
      return KiwiContainer()
          .resolve<ScanAccountDirBloc>("ScanAccountDirBloc($id)");
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ScanAccountDirBloc._(account);
      KiwiContainer().registerInstance<ScanAccountDirBloc>(bloc,
          name: "ScanAccountDirBloc($id)");
      return bloc;
    }
  }

  @override
  transformEvents(Stream<ScanAccountDirBlocEvent> events, transitionFn) {
    return super.transformEvents(events.distinct((a, b) {
      // only handle ScanAccountDirBlocQuery
      final r = a is ScanAccountDirBlocQuery &&
          b is ScanAccountDirBlocQuery &&
          a == b;
      if (r) {
        _log.fine(
            "[transformEvents] Skip identical ScanAccountDirBlocQuery event");
      }
      return r;
    }), transitionFn);
  }

  @override
  mapEventToState(ScanAccountDirBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ScanAccountDirBlocQueryBase) {
      yield* _onEventQuery(event);
    } else if (event is _ScanAccountDirBlocExternalEvent) {
      yield* _onExternalEvent(event);
    }
  }

  @override
  close() {
    _fileRemovedEventListener.end();
    _filePropertyUpdatedEventListener.end();
    _fileTrashbinRestoredEventListener.end();
    _fileMovedEventListener.end();
    _prefUpdatedEventListener.end();
    _accountPrefUpdatedEventListener.end();

    _refreshThrottler.clear();
    return super.close();
  }

  Stream<ScanAccountDirBlocState> _onEventQuery(
      ScanAccountDirBlocQueryBase ev) async* {
    yield ScanAccountDirBlocLoading(state.files);
    bool hasContent = state.files.isNotEmpty;

    if (!hasContent) {
      // show something instantly on first load
      ScanAccountDirBlocState cacheState = const ScanAccountDirBlocInit();
      await for (final s in _queryOffline(ev, () => cacheState)) {
        cacheState = s;
      }
      yield ScanAccountDirBlocLoading(cacheState.files);
      hasContent = cacheState.files.isNotEmpty;
    }

    ScanAccountDirBlocState newState = const ScanAccountDirBlocInit();
    if (!hasContent) {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
        yield s;
      }
    } else {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
      }
      if (newState is ScanAccountDirBlocSuccess) {
        yield newState;
      } else if (newState is ScanAccountDirBlocFailure) {
        yield ScanAccountDirBlocFailure(state.files, newState.exception);
      }
    }
  }

  Stream<ScanAccountDirBlocState> _onExternalEvent(
      _ScanAccountDirBlocExternalEvent ev) async* {
    yield ScanAccountDirBlocInconsistent(state.files);
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ScanAccountDirBlocInit) {
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
    ])) {
      // not interested
      return;
    }
    if (state is ScanAccountDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (!_isFileOfInterest(ev.file)) {
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
    if (state is ScanAccountDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  void _onFileMovedEvent(FileMovedEvent ev) {
    if (state is ScanAccountDirBlocInit) {
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

  void _onPrefUpdatedEvent(PrefUpdatedEvent ev) {
    if (state is ScanAccountDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (ev.key == PrefKey.accounts3) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  void _onAccountPrefUpdatedEvent(AccountPrefUpdatedEvent ev) {
    if (state is ScanAccountDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (ev.key == PrefKey.shareFolder &&
        identical(ev.pref, AccountPref.of(account))) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  Stream<ScanAccountDirBlocState> _queryOffline(ScanAccountDirBlocQueryBase ev,
          ScanAccountDirBlocState Function() getState) =>
      _queryWithFileDataSource(ev, getState, FileAppDbDataSource(AppDb()));

  Stream<ScanAccountDirBlocState> _queryOnline(ScanAccountDirBlocQueryBase ev,
      ScanAccountDirBlocState Function() getState) {
    final stream = _queryWithFileDataSource(ev, getState,
        FileCachedDataSource(AppDb(), shouldCheckCache: _shouldCheckCache));
    _shouldCheckCache = false;
    return stream;
  }

  Stream<ScanAccountDirBlocState> _queryWithFileDataSource(
      ScanAccountDirBlocQueryBase ev,
      ScanAccountDirBlocState Function() getState,
      FileDataSource dataSrc) async* {
    try {
      final fileRepo = FileRepo(dataSrc);
      // include files shared with this account
      final settings = AccountPref.of(account);
      final shareDir = File(
          path: file_util.unstripPath(account, settings.getShareFolderOr()));
      bool isShareDirIncluded = false;

      for (final r in account.roots) {
        final dir = File(path: file_util.unstripPath(account, r));
        final dataStream = ScanDir(fileRepo)(account, dir);
        await for (final d in dataStream) {
          if (d is ExceptionEvent) {
            throw d.error;
          }
          yield ScanAccountDirBlocLoading(getState().files + d);
        }

        isShareDirIncluded |= file_util.isOrUnderDir(shareDir, dir);
      }

      if (!isShareDirIncluded) {
        final files = await Ls(fileRepo)(
          account,
          File(
            path: file_util.unstripPath(account, settings.getShareFolderOr()),
          ),
        );
        final sharedFiles =
            files.where((f) => !f.isOwned(account.username)).toList();
        yield ScanAccountDirBlocSuccess(getState().files + sharedFiles);
      } else {
        yield ScanAccountDirBlocSuccess(getState().files);
      }
    } catch (e, stackTrace) {
      _log.severe(
          "[_queryWithFileDataSource] Exception while request", e, stackTrace);
      yield ScanAccountDirBlocFailure(getState().files, e);
    }
  }

  bool _isFileOfInterest(File file) {
    if (!file_util.isSupportedFormat(file)) {
      return false;
    }

    for (final r in account.roots) {
      final dir = File(path: file_util.unstripPath(account, r));
      if (file_util.isUnderDir(file, dir)) {
        return true;
      }
    }

    final settings = AccountPref.of(account);
    final shareDir =
        File(path: file_util.unstripPath(account, settings.getShareFolderOr()));
    if (file_util.isUnderDir(file, shareDir)) {
      return true;
    }
    return false;
  }

  final Account account;

  late final _fileRemovedEventListener =
      AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
  late final _filePropertyUpdatedEventListener =
      AppEventListener<FilePropertyUpdatedEvent>(_onFilePropertyUpdatedEvent);
  late final _fileTrashbinRestoredEventListener =
      AppEventListener<FileTrashbinRestoredEvent>(_onFileTrashbinRestoredEvent);
  late final _fileMovedEventListener =
      AppEventListener<FileMovedEvent>(_onFileMovedEvent);
  late final _prefUpdatedEventListener =
      AppEventListener<PrefUpdatedEvent>(_onPrefUpdatedEvent);
  late final _accountPrefUpdatedEventListener =
      AppEventListener<AccountPrefUpdatedEvent>(_onAccountPrefUpdatedEvent);

  late final _refreshThrottler = Throttler(
    onTriggered: (_) {
      add(const _ScanAccountDirBlocExternalEvent());
    },
    logTag: "ScanAccountDirBloc.refresh",
  );

  bool _shouldCheckCache = true;

  static final _log = Logger("bloc.scan_dir.ScanAccountDirBloc");
}
