import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/touch_token_manager.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:nc_photos/use_case/scan_dir.dart';
import 'package:nc_photos/use_case/scan_dir_offline.dart';

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
    _favoriteResyncedEventListener.begin();
    _prefUpdatedEventListener.begin();
    _accountPrefUpdatedEventListener.begin();
  }

  static ScanAccountDirBloc of(Account account) {
    final name =
        bloc_util.getInstNameForRootAwareAccount("ScanAccountDirBloc", account);
    try {
      _log.fine("[of] Resolving bloc for '$name'");
      return KiwiContainer().resolve<ScanAccountDirBloc>(name);
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ScanAccountDirBloc._(account);
      KiwiContainer().registerInstance<ScanAccountDirBloc>(bloc, name: name);
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
    _favoriteResyncedEventListener.end();
    _prefUpdatedEventListener.end();
    _accountPrefUpdatedEventListener.end();

    _refreshThrottler.clear();
    return super.close();
  }

  Stream<ScanAccountDirBlocState> _onEventQuery(
      ScanAccountDirBlocQueryBase ev) async* {
    yield ScanAccountDirBlocLoading(state.files);
    bool hasContent = state.files.isNotEmpty;

    List<File> cacheFiles = [];
    if (!hasContent) {
      // show something instantly on first load
      final stopwatch = Stopwatch()..start();
      cacheFiles = await _queryOffline(ev);
      _log.info(
          "[_onEventQuery] Elapsed time (_queryOffline): ${stopwatch.elapsedMilliseconds}ms");
      yield ScanAccountDirBlocLoading(cacheFiles);
      hasContent = cacheFiles.isNotEmpty;
    }

    yield* _queryOnline(ev, hasContent ? cacheFiles : null);
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
      FilePropertyUpdatedEvent.propFavorite,
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

  void _onFavoriteResyncedEvent(FavoriteResyncedEvent ev) {
    if (state is ScanAccountDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if ((ev.newFavorites + ev.removedFavorites).any(_isFileOfInterest)) {
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

  Future<List<File>> _queryOffline(ScanAccountDirBlocQueryBase ev) async {
    final c = KiwiContainer().resolve<DiContainer>();
    final files = <File>[];
    for (final r in account.roots) {
      try {
        final dir = File(path: file_util.unstripPath(account, r));
        files.addAll(await ScanDirOffline(c)(account, dir));
      } catch (e, stackTrace) {
        _log.shout(
            "[_queryOffline] Failed while ScanDirOffline: ${logFilename(r)}",
            e,
            stackTrace);
      }
    }
    return files;
  }

  Stream<ScanAccountDirBlocState> _queryOnline(
      ScanAccountDirBlocQueryBase ev, List<File>? cache) async* {
    // 1st pass: scan for new files
    var files = <File>[];
    {
      final stopwatch = Stopwatch()..start();
      final fileRepo = FileRepo(FileCachedDataSource(AppDb(),
          forwardCacheManager: FileForwardCacheManager(AppDb())));
      final fileRepoNoCache = FileRepo(FileCachedDataSource(AppDb()));
      await for (final event in _queryWithFileRepo(fileRepo, ev,
          fileRepoForShareDir: fileRepoNoCache)) {
        if (event is ExceptionEvent) {
          _log.shout("[_queryOnline] Exception while request (1st pass)",
              event.error, event.stackTrace);
          yield ScanAccountDirBlocFailure(cache ?? files, event.error);
          return;
        }
        files.addAll(event);
        if (cache == null) {
          // only emit partial results if there's no cache
          yield ScanAccountDirBlocLoading(files);
        }
      }
      _log.info(
          "[_queryOnline] Elapsed time (pass1): ${stopwatch.elapsedMilliseconds}ms");
    }

    try {
      if (_shouldCheckCache) {
        // 2nd pass: check outdated cache
        _shouldCheckCache = false;

        // announce the result of the 1st pass
        // if cache == null, we have already emitted the results in the loop
        if (cache != null || files.isEmpty) {
          // emit results from remote
          yield ScanAccountDirBlocLoading(files);
        }

        files = await _queryOnlinePass2(ev, files);
      }
    } catch (e, stackTrace) {
      _log.shout(
          "[_queryOnline] Failed while _queryOnlinePass2", e, stackTrace);
    }
    yield ScanAccountDirBlocSuccess(files);
  }

  Future<List<File>> _queryOnlinePass2(
      ScanAccountDirBlocQueryBase ev, List<File> pass1Files) async {
    const touchTokenManager = TouchTokenManager();
    final fileRepo = FileRepo(FileCachedDataSource(AppDb(),
        shouldCheckCache: true,
        forwardCacheManager: FileForwardCacheManager(AppDb())));
    final remoteTouchEtag =
        await touchTokenManager.getRemoteRootEtag(fileRepo, account);
    if (remoteTouchEtag == null) {
      _log.info("[_queryOnlinePass2] remoteTouchEtag == null");
      await touchTokenManager.setLocalRootEtag(account, null);
      return pass1Files;
    }
    final localTouchEtag = await touchTokenManager.getLocalRootEtag(account);
    if (remoteTouchEtag == localTouchEtag) {
      _log.info("[_queryOnlinePass2] remoteTouchEtag matched");
      return pass1Files;
    }

    final stopwatch = Stopwatch()..start();
    final fileRepoNoCache =
        FileRepo(FileCachedDataSource(AppDb(), shouldCheckCache: true));
    final newFiles = <File>[];
    await for (final event in _queryWithFileRepo(fileRepo, ev,
        fileRepoForShareDir: fileRepoNoCache)) {
      if (event is ExceptionEvent) {
        _log.shout("[_queryOnlinePass2] Exception while request (2nd pass)",
            event.error, event.stackTrace);
        return pass1Files;
      }
      newFiles.addAll(event);
    }
    _log.info(
        "[_queryOnlinePass2] Elapsed time (pass2): ${stopwatch.elapsedMilliseconds}ms");
    _log.info("[_queryOnlinePass2] Save new touch root etag: $remoteTouchEtag");
    await touchTokenManager.setLocalRootEtag(account, remoteTouchEtag);
    return newFiles;
  }

  /// Emit all files under this account
  ///
  /// Emit List<File> or ExceptionEvent
  Stream<dynamic> _queryWithFileRepo(
    FileRepo fileRepo,
    ScanAccountDirBlocQueryBase ev, {
    FileRepo? fileRepoForShareDir,
  }) async* {
    final settings = AccountPref.of(account);
    final shareDir =
        File(path: file_util.unstripPath(account, settings.getShareFolderOr()));
    bool isShareDirIncluded = false;

    for (final r in account.roots) {
      final dir = File(path: file_util.unstripPath(account, r));
      yield* ScanDir(fileRepo)(account, dir);
      isShareDirIncluded |= file_util.isOrUnderDir(shareDir, dir);
    }

    if (!isShareDirIncluded) {
      _log.info("[_queryWithFileRepo] Explicitly scanning share folder");
      try {
        final files = await Ls(fileRepoForShareDir ?? fileRepo)(
          account,
          File(
            path: file_util.unstripPath(account, settings.getShareFolderOr()),
          ),
        );
        yield files
            .where((f) =>
                file_util.isSupportedFormat(f) && !f.isOwned(account.username))
            .toList();
      } catch (e, stackTrace) {
        yield ExceptionEvent(e, stackTrace);
      }
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
  late final _favoriteResyncedEventListener =
      AppEventListener<FavoriteResyncedEvent>(_onFavoriteResyncedEvent);
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
