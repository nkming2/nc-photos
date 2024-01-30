import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/controller/account_pref_controller.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/progress_util.dart';
import 'package:nc_photos/rx_extension.dart';
import 'package:nc_photos/use_case/file/list_file.dart';
import 'package:nc_photos/use_case/find_file_descriptor.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/sync_dir.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/lazy.dart';
import 'package:np_common/object_util.dart';
import 'package:np_common/or_null.dart';
import 'package:np_db/np_db.dart';
import 'package:rxdart/rxdart.dart';
import 'package:to_string/to_string.dart';

part 'files_controller.g.dart';

abstract class FilesStreamEvent {
  /// All files as a ordered list
  List<FileDescriptor> get data;

  /// All files as a map with the fileId as key
  Map<int, FileDescriptor> get dataMap;
  bool get hasNext;
}

@npLog
class FilesController {
  FilesController(
    this._c, {
    required this.account,
    required this.accountPrefController,
  }) {
    _subscriptions.add(accountPrefController.shareFolder.listen((event) {
      // sync remote if share folder is modified
      if (_isDataStreamInited) {
        syncRemote();
      }
    }));
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _dataStreamController.close();
  }

  /// Return a stream of files associated with [account]
  ///
  /// The returned stream will emit new list of files whenever there are
  /// changes to the files (e.g., new file, removed file, etc)
  ///
  /// There's no guarantee that the returned list is always sorted in some ways,
  /// callers must sort it by themselves if the ordering is important
  ValueStream<FilesStreamEvent> get stream {
    if (!_isDataStreamInited) {
      _isDataStreamInited = true;
      _load();
    }
    return _dataStreamController.stream;
  }

  Future<void> syncRemote({
    void Function(Progress progress)? onProgressUpdate,
  }) async {
    if (_isSyncing) {
      _log.fine("[syncRemote] Skipped as another sync running");
      return;
    }
    _isSyncing = true;
    try {
      final shareDir = File(
        path: file_util.unstripPath(
            account, accountPrefController.shareFolder.value),
      );
      var isShareDirIncluded = false;

      _c.touchManager.clearTouchCache();
      final progress = IntProgress(account.roots.length);
      for (final r in account.roots) {
        final dirPath = file_util.unstripPath(account, r);
        await SyncDir(_c)(
          account,
          dirPath,
          onProgressUpdate: (value) {
            final merged = progress.progress + progress.step * value.progress;
            onProgressUpdate?.call(Progress(merged, value.text));
          },
        );
        isShareDirIncluded |=
            file_util.isOrUnderDirPath(shareDir.path, dirPath);
        progress.next();
      }

      if (!isShareDirIncluded) {
        _log.info("[syncRemote] Explicitly scanning share folder");
        await SyncDir(_c)(account, shareDir.path, isRecursive: false);
      }
      // load the synced content to stream
      unawaited(_reload());
    } finally {
      _isSyncing = false;
    }
  }

  /// Update files property and return number of files updated
  Future<void> updateProperty(
    List<FileDescriptor> files, {
    OrNull<Metadata>? metadata,
    OrNull<bool>? isArchived,
    OrNull<DateTime>? overrideDateTime,
    bool? isFavorite,
    OrNull<ImageLocation>? location,
    Exception? Function(List<int> fileIds) errorBuilder =
        UpdatePropertyFailureError.new,
  }) async {
    final backups = <int, FileDescriptor>{};
    // file ids that need to be queried again to get the correct
    // FileDescriptor.fdDateTime
    final outdated = <int>[];
    await _mutex.protect(() async {
      final next = Map.of(_dataStreamController.value.files);
      for (final f in files) {
        final original = next[f.fdId];
        if (original == null) {
          _log.warning("[updateProperty] File not found: $f");
          continue;
        }
        backups[f.fdId] = original;
        if (original is File) {
          next[f.fdId] = original.copyWith(
            metadata: metadata,
            isArchived: isArchived,
            overrideDateTime: overrideDateTime,
            isFavorite: isFavorite,
            location: location,
          );
        } else {
          next[f.fdId] = original.copyWith(
            fdIsArchived: isArchived == null ? null : (isArchived.obj ?? false),
            // in case of unsetting, we can't work out the new value here
            fdDateTime: overrideDateTime?.obj,
            fdIsFavorite: isFavorite,
          );
          if (OrNull.isSetNull(overrideDateTime)) {
            outdated.add(f.fdId);
          }
        }
      }
      _dataStreamController
          .addWithValue((value) => value.copyWith(files: next));
    });
    final failures = <int>[];
    for (final f in files) {
      try {
        await UpdateProperty(_c)(
          account,
          f,
          metadata: metadata,
          isArchived: isArchived,
          overrideDateTime: overrideDateTime,
          favorite: isFavorite,
          location: location,
        );
      } catch (e, stackTrace) {
        _log.severe(
            "[updateProperty] Failed while UpdateProperty: ${logFilename(f.fdPath)}",
            e,
            stackTrace);
        failures.add(f.fdId);
        outdated.remove(f.fdId);
      }
    }
    if (failures.isNotEmpty) {
      // restore
      final next = Map.of(_dataStreamController.value.files);
      for (final f in failures) {
        if (backups.containsKey(f)) {
          next[f] = backups[f]!;
        }
      }
      _dataStreamController
          .addWithValue((value) => value.copyWith(files: next));
      errorBuilder(failures)?.let(_dataStreamController.addError);
    }
    // TODO query outdated
  }

  Future<void> remove(
    List<FileDescriptor> files, {
    Exception? Function(List<int> fileIds) errorBuilder =
        RemoveFailureError.new,
  }) async {
    final backups = <int, FileDescriptor>{};
    await _mutex.protect(() async {
      final next = Map.of(_dataStreamController.value.files);
      for (final f in files) {
        final original = next.remove(f.fdId);
        if (original == null) {
          _log.warning("[remove] File not found: $f");
          continue;
        }
        backups[f.fdId] = original;
      }
      _dataStreamController
          .addWithValue((value) => value.copyWith(files: next));
    });
    final failures = <int>[];
    try {
      await Remove(_c)(
        account,
        files,
        onError: (index, value, error, stackTrace) {
          _log.severe(
              "[remove] Failed while Remove: ${logFilename(value.fdPath)}",
              error,
              stackTrace);
          failures.add(value.fdId);
        },
      );
    } catch (e, stackTrace) {
      _log.severe("[remove] Failed while Remove", e, stackTrace);
      failures.addAll(files.map((e) => e.fdId));
    }
    if (failures.isNotEmpty) {
      // restore
      final next = LinkedHashMap.of(_dataStreamController.value.files);
      for (final f in failures) {
        if (backups.containsKey(f)) {
          next[f] = backups[f]!;
        }
      }
      _dataStreamController
          .addWithValue((value) => value.copyWith(files: next));
      errorBuilder(failures)?.let(_dataStreamController.addError);
    }
  }

  Future<void> applySyncResult({
    DbSyncIdResult? favorites,
    List<int>? fileExifs,
  }) async {
    if (favorites?.isNotEmpty != true && fileExifs?.isNotEmpty != true) {
      return;
    }

    // do async ops first
    final fileExifFiles =
        await fileExifs?.letFuture((e) async => await FindFileDescriptor(_c)(
              account,
              e,
              onFileNotFound: (id) {
                _log.warning("[applySyncResult] File id not found: $id");
              },
            ));

    final next = LinkedHashMap.of(_dataStreamController.value.files);
    if (favorites != null && favorites.isNotEmpty) {
      _applySyncFavoriteResult(next, favorites);
    }
    if (fileExifFiles != null && fileExifFiles.isNotEmpty) {
      _applySyncFileExifResult(next, fileExifFiles);
    }
    _dataStreamController.addWithValue((value) => value.copyWith(files: next));
  }

  void _applySyncFavoriteResult(
      Map<int, FileDescriptor> next, DbSyncIdResult result) {
    for (final id in result.insert) {
      final f = next[id];
      if (f == null) {
        _log.warning("[_applySyncFavoriteResult] File id not found: $id");
        continue;
      }
      if (f is File) {
        next[id] = f.copyWith(isFavorite: true);
      } else {
        next[id] = f.copyWith(fdIsFavorite: true);
      }
    }
    for (final id in result.delete) {
      final f = next[id];
      if (f == null) {
        _log.warning("[_applySyncFavoriteResult] File id not found: $id");
        continue;
      }
      if (f is File) {
        next[id] = f.copyWith(isFavorite: false);
      } else {
        next[id] = f.copyWith(fdIsFavorite: false);
      }
    }
  }

  void _applySyncFileExifResult(
      Map<int, FileDescriptor> next, List<FileDescriptor> results) {
    for (final f in results) {
      next[f.fdId] = f;
    }
  }

  Future<void> _load() async {
    var lastData = _FilesStreamEvent(
      files: const {},
      hasNext: false,
    );
    final completer = Completer();
    ListFile(_c)(
      account,
      file_util.unstripPath(account, accountPrefController.shareFolder.value),
    ).listen(
      (ev) {
        lastData = _convertListResultsToEvent(ev, hasNext: true);
        _dataStreamController.add(lastData);
      },
      onError: _dataStreamController.addError,
      onDone: () => completer.complete(),
    );
    await completer.future;
    _dataStreamController.add(lastData.copyWith(hasNext: false));
  }

  Future<void> _reload() async {
    var results = <FileDescriptor>[];
    final completer = Completer();
    ListFile(_c)(
      account,
      file_util.unstripPath(account, accountPrefController.shareFolder.value),
    ).listen(
      (ev) {
        results = ev;
      },
      onError: _dataStreamController.addError,
      onDone: () => completer.complete(),
    );
    await completer.future;
    _dataStreamController
        .add(_convertListResultsToEvent(results, hasNext: false));
  }

  _FilesStreamEvent _convertListResultsToEvent(
    List<FileDescriptor> results, {
    required bool hasNext,
  }) {
    return _FilesStreamEvent(
      files: {
        for (final f in results) f.fdId: f,
      },
      hasNext: hasNext,
    );
  }

  final DiContainer _c;
  final Account account;
  final AccountPrefController accountPrefController;

  var _isDataStreamInited = false;
  final _dataStreamController = BehaviorSubject.seeded(
    _FilesStreamEvent(
      files: const {},
      hasNext: true,
    ),
  );

  final _mutex = Mutex();
  var _isSyncing = false;
  final _subscriptions = <StreamSubscription>[];
}

@toString
class UpdatePropertyFailureError implements Exception {
  const UpdatePropertyFailureError(this.fileIds);

  @override
  String toString() => _$toString();

  final List<int> fileIds;
}

@toString
class RemoveFailureError implements Exception {
  const RemoveFailureError(this.fileIds);

  @override
  String toString() => _$toString();

  final List<int> fileIds;
}

class _FilesStreamEvent implements FilesStreamEvent {
  _FilesStreamEvent({
    required this.files,
    Lazy<List<FileDescriptor>>? dataLazy,
    required this.hasNext,
  }) {
    this.dataLazy = dataLazy ?? (Lazy(() => files.values.toList()));
  }

  _FilesStreamEvent copyWith({
    Map<int, FileDescriptor>? files,
    bool? hasNext,
  }) {
    return _FilesStreamEvent(
      files: files ?? this.files,
      dataLazy: (files == null) ? dataLazy : null,
      hasNext: hasNext ?? this.hasNext,
    );
  }

  @override
  List<FileDescriptor> get data => dataLazy();
  @override
  Map<int, FileDescriptor> get dataMap => files;

  final Map<int, FileDescriptor> files;
  late final Lazy<List<FileDescriptor>> dataLazy;

  /// If true, the results are intermediate values and may not represent the
  /// latest state
  @override
  final bool hasNext;
}
