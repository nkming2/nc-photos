import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/event/native_event.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/throttler.dart';
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
    final c = KiwiContainer().resolve<DiContainer>();
    assert(require(c));
    assert(ScanDirOffline.require(c));
    _c = c;

    _fileRemovedEventListener.begin();
    _filePropertyUpdatedEventListener.begin();
    _fileTrashbinRestoredEventListener.begin();
    _fileMovedEventListener.begin();
    _favoriteResyncedEventListener.begin();
    _prefUpdatedEventListener.begin();
    _accountPrefUpdatedEventListener.begin();

    _nativeFileExifUpdatedListener?.begin();
    _imageProcessorUploadSuccessListener?.begin();

    on<ScanAccountDirBlocEvent>(_onEvent, transformer: ((events, mapper) {
      return events.distinct((a, b) {
        // only handle ScanAccountDirBlocQuery
        final r = a is ScanAccountDirBlocQuery && b is ScanAccountDirBlocQuery;
        if (r) {
          _log.fine("[on] Skip identical ScanAccountDirBlocQuery event");
        }
        return r;
      }).asyncExpand(mapper);
    }));
  }

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.fileRepo) &&
      DiContainer.has(c, DiType.touchManager);

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
  close() {
    _fileRemovedEventListener.end();
    _filePropertyUpdatedEventListener.end();
    _fileTrashbinRestoredEventListener.end();
    _fileMovedEventListener.end();
    _favoriteResyncedEventListener.end();
    _prefUpdatedEventListener.end();
    _accountPrefUpdatedEventListener.end();

    _nativeFileExifUpdatedListener?.end();
    _imageProcessorUploadSuccessListener?.end();

    _refreshThrottler.clear();
    return super.close();
  }

  Future<void> _onEvent(ScanAccountDirBlocEvent event,
      Emitter<ScanAccountDirBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ScanAccountDirBlocQueryBase) {
      await _onEventQuery(event, emit);
    } else if (event is _ScanAccountDirBlocExternalEvent) {
      await _onExternalEvent(event, emit);
    }
  }

  Future<void> _onEventQuery(ScanAccountDirBlocQueryBase ev,
      Emitter<ScanAccountDirBlocState> emit) async {
    _log.info("[_onEventQuery] $ev");
    emit(ScanAccountDirBlocLoading(state.files));
    final hasContent = state.files.isNotEmpty;

    final stopwatch = Stopwatch()..start();
    if (!hasContent) {
      try {
        emit(ScanAccountDirBlocLoading(await _queryOfflineMini(ev)));
      } catch (e, stackTrace) {
        _log.shout(
            "[_onEventQuery] Failed while _queryOfflineMini", e, stackTrace);
      }
      _log.info(
          "[_onEventQuery] Elapsed time (_queryOfflineMini): ${stopwatch.elapsedMilliseconds}ms");
      stopwatch.reset();
    }
    final cacheFiles = await _queryOffline(ev);
    _log.info(
        "[_onEventQuery] Elapsed time (_queryOffline): ${stopwatch.elapsedMilliseconds}ms, ${cacheFiles.length} files");
    if (!hasContent) {
      // show something instantly on first load
      emit(ScanAccountDirBlocLoading(
          cacheFiles.where((f) => file_util.isSupportedFormat(f)).toList()));
    }

    await _queryOnline(ev, emit, cacheFiles);
  }

  Future<void> _onExternalEvent(_ScanAccountDirBlocExternalEvent ev,
      Emitter<ScanAccountDirBlocState> emit) async {
    emit(ScanAccountDirBlocInconsistent(state.files));
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ScanAccountDirBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (_isFileOfInterest(ev.file)) {
      _log.info("[_onFileRemovedEvent] Request refresh");
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

    _log.info("[_onFilePropertyUpdatedEvent] Request refresh");
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
    _log.info("[_onFileTrashbinRestoredEvent] Request refresh");
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
      _log.info("[_onFileMovedEvent] Request refresh");
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
    if (ev.account.compareServerIdentity(account)) {
      _log.info("[_onFavoriteResyncedEvent] Request refresh");
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
      _log.info("[_onPrefUpdatedEvent] Request refresh");
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
      _log.info("[_onAccountPrefUpdatedEvent] Request refresh");
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  void _onNativeFileExifUpdated(FileExifUpdatedEvent ev) {
    _log.info("[_onNativeFileExifUpdated] Request refresh");
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  void _onImageProcessorUploadSuccessEvent(
      ImageProcessorUploadSuccessEvent ev) {
    _log.info("[_onImageProcessorUploadSuccessEvent] Request refresh");
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  /// Query a small amount of files to give an illusion of quick startup
  Future<List<File>> _queryOfflineMini(ScanAccountDirBlocQueryBase ev) async {
    return await ScanDirOfflineMini(_c)(
      account,
      account.roots.map((r) => File(path: file_util.unstripPath(account, r))),
      100,
      isOnlySupportedFormat: true,
    );
  }

  Future<List<File>> _queryOffline(ScanAccountDirBlocQueryBase ev) async {
    final files = <File>[];
    for (final r in account.roots) {
      try {
        final dir = File(path: file_util.unstripPath(account, r));
        files.addAll(await ScanDirOffline(_c)(account, dir,
            isOnlySupportedFormat: false));
      } catch (e, stackTrace) {
        _log.shout(
            "[_queryOffline] Failed while ScanDirOffline: ${logFilename(r)}",
            e,
            stackTrace);
      }
    }
    return files;
  }

  Future<void> _queryOnline(ScanAccountDirBlocQueryBase ev,
      Emitter<ScanAccountDirBlocState> emit, List<File> cache) async {
    // 1st pass: scan for new files
    var files = <File>[];
    final cacheMap = FileForwardCacheManager.prepareFileMap(cache);
    final stopwatch = Stopwatch()..start();
    _c.touchManager.clearTouchCache();
    final fileRepo = FileRepo(FileCachedDataSource(
      _c,
      forwardCacheManager: FileForwardCacheManager(_c, cacheMap),
      shouldCheckCache: true,
    ));
    await for (final event
        in _queryWithFileRepo(fileRepo, ev, fileRepoForShareDir: _c.fileRepo)) {
      if (event is ExceptionEvent) {
        _log.shout("[_queryOnline] Exception while request", event.error,
            event.stackTrace);
        emit(ScanAccountDirBlocFailure(
            cache.isEmpty
                ? files
                : cache.where((f) => file_util.isSupportedFormat(f)).toList(),
            event.error));
        return;
      }
      files.addAll(event);
      if (cache.isEmpty) {
        // only emit partial results if there's no cache
        emit(ScanAccountDirBlocLoading(files.toList()));
      }
    }
    _log.info(
        "[_queryOnline] Elapsed time (_queryOnline): ${stopwatch.elapsedMilliseconds}ms, ${files.length} files");

    emit(ScanAccountDirBlocSuccess(files));
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
                file_util.isSupportedFormat(f) && !f.isOwned(account.userId))
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

  late final DiContainer _c;

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

  late final _nativeFileExifUpdatedListener = platform_k.isWeb
      ? null
      : NativeEventListener<FileExifUpdatedEvent>(_onNativeFileExifUpdated);
  late final _imageProcessorUploadSuccessListener = platform_k.isWeb
      ? null
      : NativeEventListener<ImageProcessorUploadSuccessEvent>(
          _onImageProcessorUploadSuccessEvent);

  late final _refreshThrottler = Throttler(
    onTriggered: (_) {
      add(const _ScanAccountDirBlocExternalEvent());
    },
    logTag: "ScanAccountDirBloc.refresh",
  );

  static final _log = Logger("bloc.scan_dir.ScanAccountDirBloc");
}
