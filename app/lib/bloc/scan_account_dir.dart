import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/bloc/progress.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/event/native_event.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/progress_util.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:nc_photos/use_case/scan_dir.dart';
import 'package:nc_photos/use_case/scan_dir_offline.dart';
import 'package:nc_photos/use_case/sync_dir.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'scan_account_dir.g.dart';

abstract class ScanAccountDirBlocEvent {
  const ScanAccountDirBlocEvent();
}

@toString
abstract class ScanAccountDirBlocQueryBase extends ScanAccountDirBlocEvent {
  const ScanAccountDirBlocQueryBase({
    this.progressBloc,
  });

  @override
  String toString() => _$toString();

  /// Get notified about the query progress
  final ProgressBloc? progressBloc;
}

class ScanAccountDirBlocQuery extends ScanAccountDirBlocQueryBase {
  const ScanAccountDirBlocQuery({
    super.progressBloc,
  });
}

class ScanAccountDirBlocRefresh extends ScanAccountDirBlocQueryBase {
  const ScanAccountDirBlocRefresh({
    super.progressBloc,
  });
}

/// An external event has happened and may affect the state of this bloc
@toString
class _ScanAccountDirBlocExternalEvent extends ScanAccountDirBlocEvent {
  const _ScanAccountDirBlocExternalEvent();

  @override
  String toString() => _$toString();
}

@toString
abstract class ScanAccountDirBlocState {
  const ScanAccountDirBlocState(this.files);

  @override
  String toString() => _$toString();

  final List<FileDescriptor> files;
}

class ScanAccountDirBlocInit extends ScanAccountDirBlocState {
  const ScanAccountDirBlocInit() : super(const []);
}

class ScanAccountDirBlocLoading extends ScanAccountDirBlocState {
  const ScanAccountDirBlocLoading(
    List<FileDescriptor> files, {
    this.isInitialLoad = false,
  }) : super(files);

  final bool isInitialLoad;
}

class ScanAccountDirBlocSuccess extends ScanAccountDirBlocState {
  const ScanAccountDirBlocSuccess(List<FileDescriptor> files) : super(files);
}

@toString
class ScanAccountDirBlocFailure extends ScanAccountDirBlocState {
  const ScanAccountDirBlocFailure(List<FileDescriptor> files, this.exception)
      : super(files);

  @override
  String toString() => _$toString();

  final dynamic exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ScanAccountDirBlocInconsistent extends ScanAccountDirBlocState {
  const ScanAccountDirBlocInconsistent(List<FileDescriptor> files)
      : super(files);
}

/// A bloc that return all files under a dir recursively
///
/// See [ScanDir]
@npLog
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
      emit(ScanAccountDirBlocLoading(cacheFiles));
    }

    if (!hasContent && cacheFiles.isEmpty) {
      emit(const ScanAccountDirBlocLoading([], isInitialLoad: true));
    }

    stopwatch.reset();
    final bool hasUpdate;
    try {
      hasUpdate = await _syncOnline(
        ev,
        onProgressUpdate: (value) {
          if (ev.progressBloc?.isClosed == false) {
            ev.progressBloc!
                .add(ProgressBlocUpdate(value.progress, value.text));
          }
        },
      );
    } catch (e, stackTrace) {
      _log.shout("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ScanAccountDirBlocFailure(cacheFiles, e));
      return;
    }
    _log.info(
        "[_onEventQuery] Elapsed time (_syncOnline): ${stopwatch.elapsedMilliseconds}ms, hasUpdate: $hasUpdate");
    if (hasUpdate) {
      // content updated, reload from db
      stopwatch.reset();
      final newFiles = await _queryOffline(ev);
      _log.info(
          "[_onEventQuery] Elapsed time (_queryOffline) 2nd pass: ${stopwatch.elapsedMilliseconds}ms, ${newFiles.length} files");
      emit(ScanAccountDirBlocSuccess(newFiles));
    } else {
      emit(ScanAccountDirBlocSuccess(cacheFiles));
    }
  }

  Future<bool> _syncOnline(
    ScanAccountDirBlocQueryBase ev, {
    ValueChanged<Progress>? onProgressUpdate,
  }) async {
    final settings = AccountPref.of(account);
    final shareDir =
        File(path: file_util.unstripPath(account, settings.getShareFolderOr()));
    bool isShareDirIncluded = false;

    bool hasUpdate = false;
    _c.touchManager.clearTouchCache();
    final progress = IntProgress(account.roots.length);
    for (final r in account.roots) {
      final dirPath = file_util.unstripPath(account, r);
      hasUpdate |= await SyncDir(_c)(
        account,
        dirPath,
        onProgressUpdate: (value) {
          final merged = progress.progress + progress.step * value.progress;
          onProgressUpdate?.call(Progress(merged, value.text));
        },
      );
      isShareDirIncluded |=
          file_util.isOrUnderDir(shareDir, File(path: dirPath));
      progress.next();
    }

    if (!isShareDirIncluded) {
      _log.info("[_syncOnline] Explicitly scanning share folder");
      hasUpdate |= await SyncDir(_c)(
        account,
        file_util.unstripPath(account, settings.getShareFolderOr()),
        isRecursive: false,
      );
    }
    return hasUpdate;
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
    if (ev.key == AccountPrefKey.shareFolder &&
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
      scanMiniCount,
      isOnlySupportedFormat: true,
    );
  }

  Future<List<FileDescriptor>> _queryOffline(
      ScanAccountDirBlocQueryBase ev) async {
    final settings = AccountPref.of(account);
    final shareDir =
        File(path: file_util.unstripPath(account, settings.getShareFolderOr()));
    bool isShareDirIncluded = false;

    final files = <FileDescriptor>[];
    for (final r in account.roots) {
      try {
        final dir = File(path: file_util.unstripPath(account, r));
        files.addAll(await ScanDirOffline(_c)(account, dir,
            isOnlySupportedFormat: true));
        isShareDirIncluded |= file_util.isOrUnderDir(shareDir, dir);
      } catch (e, stackTrace) {
        _log.shout(
            "[_queryOffline] Failed while ScanDirOffline: ${logFilename(r)}",
            e,
            stackTrace);
      }
    }

    if (!isShareDirIncluded) {
      _log.info("[_queryOffline] Explicitly scanning share folder");
      try {
        final raw = await Ls(_c.fileRepoLocal)(account, shareDir);
        files.addAll(raw.where((f) => file_util.isSupportedFormat(f)));
      } on CacheNotFoundException catch (_) {
        // normal when there's no cache
      } catch (e, stackTrace) {
        _log.shout(
            "[_queryOffline] Failed while ScanDirOffline: ${logFilename(shareDir.path)}",
            e,
            stackTrace);
      }
    }
    return files;
  }

  bool _isFileOfInterest(FileDescriptor file) {
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

  static const scanMiniCount = 100;

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

  static final _log = _$ScanAccountDirBlocNpLog.log;
}
