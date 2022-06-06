import 'package:collection/collection.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/touch_token_manager.dart';

class FileCacheLoader {
  FileCacheLoader({
    required this.appDb,
    required this.appDbSrc,
    required this.remoteSrc,
    this.shouldCheckCache = false,
    this.forwardCacheManager,
  });

  /// Return the cached results of listing a directory [dir]
  ///
  /// Should check [isGood] before using the cache returning by this method
  Future<List<File>?> call(Account account, File dir) async {
    List<File>? cache;
    try {
      if (forwardCacheManager != null) {
        cache = await forwardCacheManager!.list(account, dir);
      } else {
        cache = await appDbSrc.list(account, dir);
      }
      // compare the cached root
      final cacheEtag =
          cache.firstWhere((f) => f.compareServerIdentity(dir)).etag!;
      // compare the etag to see if the content has been updated
      var remoteEtag = dir.etag;
      // if no etag supplied, we need to query it form remote
      remoteEtag ??= (await remoteSrc.list(account, dir, depth: 0)).first.etag;
      if (cacheEtag == remoteEtag) {
        _log.fine(
            "[list] etag matched for ${AppDbDirEntry.toPrimaryKeyForDir(account, dir)}");
        if (shouldCheckCache) {
          await _checkTouchToken(account, dir, cache);
        } else {
          _isGood = true;
        }
      } else {
        _log.info("[call] Remote content updated for ${dir.path}");
      }
    } on CacheNotFoundException catch (_) {
      // normal when there's no cache
    } catch (e, stackTrace) {
      _log.shout("[call] Cache failure", e, stackTrace);
    }
    return cache;
  }

  bool get isGood => _isGood;
  String? get remoteTouchToken => _remoteToken;

  Future<void> _checkTouchToken(
      Account account, File f, List<File> cache) async {
    final touchPath =
        "${remote_storage_util.getRemoteTouchDir(account)}/${f.strippedPath}";
    final fileRepo = FileRepo(FileCachedDataSource(appDb));
    const tokenManager = TouchTokenManager();
    String? remoteToken;
    try {
      remoteToken = await tokenManager.getRemoteToken(fileRepo, account, f);
    } catch (e, stacktrace) {
      _log.shout(
          "[_checkTouchToken] Failed getting remote token at '$touchPath'",
          e,
          stacktrace);
    }
    _remoteToken = remoteToken;

    String? localToken;
    try {
      localToken = await tokenManager.getLocalToken(account, f);
    } catch (e, stacktrace) {
      _log.shout(
          "[_checkTouchToken] Failed getting local token at '$touchPath'",
          e,
          stacktrace);
    }

    if (localToken != remoteToken) {
      _log.info(
          "[_checkTouchToken] Remote and local token differ, cache outdated");
    } else {
      _isGood = true;
    }
  }

  final AppDb appDb;
  final FileWebdavDataSource remoteSrc;
  final FileAppDbDataSource appDbSrc;
  final bool shouldCheckCache;
  final FileForwardCacheManager? forwardCacheManager;

  var _isGood = false;
  String? _remoteToken;

  static final _log = Logger("entity.file.file_cache_manager.FileCacheLoader");
}

class FileCacheUpdater {
  const FileCacheUpdater(this.appDb);

  Future<void> call(
    Account account,
    File dir, {
    required List<File> remote,
    List<File>? cache,
  }) async {
    await _cacheRemote(account, dir, remote);
    if (cache != null) {
      await _cleanUpCache(account, remote, cache);
    }
  }

  Future<void> _cacheRemote(Account account, File dir, List<File> remote) {
    return appDb.use(
      (db) => db.transaction(
          [AppDb.dirStoreName, AppDb.file2StoreName], idbModeReadWrite),
      (transaction) async {
        final dirStore = transaction.objectStore(AppDb.dirStoreName);
        final fileStore = transaction.objectStore(AppDb.file2StoreName);

        // add files to db
        await Future.wait(remote.map((f) => fileStore.put(
            AppDbFile2Entry.fromFile(account, f).toJson(),
            AppDbFile2Entry.toPrimaryKeyForFile(account, f))));

        // results from remote also contain the dir itself
        final resultGroup =
            remote.groupListsBy((f) => f.compareServerIdentity(dir));
        final remoteDir = resultGroup[true]!.first;
        final remoteChildren = resultGroup[false] ?? [];
        // add dir to db
        await dirStore.put(
            AppDbDirEntry.fromFiles(account, remoteDir, remoteChildren)
                .toJson(),
            AppDbDirEntry.toPrimaryKeyForDir(account, remoteDir));
      },
    );
  }

  /// Remove extra entries from local cache based on remote contents
  Future<void> _cleanUpCache(
      Account account, List<File> remote, List<File> cache) async {
    final removed = cache
        .where((c) => !remote.any((r) => r.compareServerIdentity(c)))
        .toList();
    if (removed.isEmpty) {
      return;
    }
    _log.info(
        "[_cleanUpCache] Removed: ${removed.map((f) => f.path).toReadableString()}");

    await appDb.use(
      (db) => db.transaction(
          [AppDb.dirStoreName, AppDb.file2StoreName], idbModeReadWrite),
      (transaction) async {
        final dirStore = transaction.objectStore(AppDb.dirStoreName);
        final fileStore = transaction.objectStore(AppDb.file2StoreName);
        for (final f in removed) {
          try {
            if (f.isCollection == true) {
              await _removeDirFromAppDb(account, f,
                  dirStore: dirStore, fileStore: fileStore);
            } else {
              await _removeFileFromAppDb(account, f, fileStore: fileStore);
            }
          } catch (e, stackTrace) {
            _log.shout(
                "[_cleanUpCache] Failed while removing file: ${logFilename(f.path)}",
                e,
                stackTrace);
          }
        }
      },
    );
  }

  final AppDb appDb;

  static final _log = Logger("entity.file.file_cache_manager.FileCacheUpdater");
}

class FileCacheRemover {
  const FileCacheRemover(this.appDb);

  /// Remove a file/dir from cache
  ///
  /// If [f] is a dir, the dir and its sub-dirs will be removed from dirStore.
  /// The files inside any of these dirs will be removed from file2Store.
  ///
  /// If [f] is a file, the file will be removed from file2Store, but no changes
  /// to dirStore.
  Future<void> call(Account account, File f) async {
    if (f.isCollection != false) {
      // removing dir is basically a superset of removing file, so we'll treat
      // unspecified file as dir
      await appDb.use(
        (db) => db.transaction(
            [AppDb.dirStoreName, AppDb.file2StoreName], idbModeReadWrite),
        (transaction) async {
          final dirStore = transaction.objectStore(AppDb.dirStoreName);
          final fileStore = transaction.objectStore(AppDb.file2StoreName);
          await _removeDirFromAppDb(account, f,
              dirStore: dirStore, fileStore: fileStore);
        },
      );
    } else {
      await appDb.use(
        (db) => db.transaction(AppDb.file2StoreName, idbModeReadWrite),
        (transaction) async {
          final fileStore = transaction.objectStore(AppDb.file2StoreName);
          await _removeFileFromAppDb(account, f, fileStore: fileStore);
        },
      );
    }
  }

  final AppDb appDb;
}

Future<void> _removeFileFromAppDb(
  Account account,
  File file, {
  required ObjectStore fileStore,
}) async {
  try {
    if (file.fileId == null) {
      final index = fileStore.index(AppDbFile2Entry.strippedPathIndexName);
      final key = await index
          .getKey(AppDbFile2Entry.toStrippedPathIndexKeyForFile(account, file));
      if (key != null) {
        _log.fine("[_removeFileFromAppDb] Removing fileStore entry: $key");
        await fileStore.delete(key);
      }
    } else {
      await AppDbFile2Entry.toPrimaryKeyForFile(account, file).run((key) {
        _log.fine("[_removeFileFromAppDb] Removing fileStore entry: $key");
        return fileStore.delete(key);
      });
    }
  } catch (e, stackTrace) {
    _log.shout(
        "[_removeFileFromAppDb] Failed removing fileStore entry: ${logFilename(file.path)}",
        e,
        stackTrace);
  }
}

/// Remove a dir and all files inside from the database
Future<void> _removeDirFromAppDb(
  Account account,
  File dir, {
  required ObjectStore dirStore,
  required ObjectStore fileStore,
}) async {
  // delete the dir itself
  try {
    await AppDbDirEntry.toPrimaryKeyForDir(account, dir).run((key) {
      _log.fine("[_removeDirFromAppDb] Removing dirStore entry: $key");
      return dirStore.delete(key);
    });
  } catch (e, stackTrace) {
    if (dir.isCollection != null) {
      _log.shout("[_removeDirFromAppDb] Failed removing dirStore entry", e,
          stackTrace);
    }
  }
  // then its children
  final childrenRange = KeyRange.bound(
    AppDbDirEntry.toPrimaryLowerKeyForSubDirs(account, dir),
    AppDbDirEntry.toPrimaryUpperKeyForSubDirs(account, dir),
  );
  for (final key in await dirStore.getAllKeys(childrenRange)) {
    _log.fine("[_removeDirFromAppDb] Removing dirStore entry: $key");
    try {
      await dirStore.delete(key);
    } catch (e, stackTrace) {
      _log.shout("[_removeDirFromAppDb] Failed removing dirStore entry", e,
          stackTrace);
    }
  }

  // delete files from fileStore
  // first the dir
  await _removeFileFromAppDb(account, dir, fileStore: fileStore);
  // then files under this dir and sub-dirs
  final range = KeyRange.bound(
    AppDbFile2Entry.toStrippedPathIndexLowerKeyForDir(account, dir),
    AppDbFile2Entry.toStrippedPathIndexUpperKeyForDir(account, dir),
  );
  final strippedPathIndex =
      fileStore.index(AppDbFile2Entry.strippedPathIndexName);
  for (final key in await strippedPathIndex.getAllKeys(range)) {
    _log.fine("[_removeDirFromAppDb] Removing fileStore entry: $key");
    try {
      await fileStore.delete(key);
    } catch (e, stackTrace) {
      _log.shout("[_removeDirFromAppDb] Failed removing fileStore entry", e,
          stackTrace);
    }
  }
}

final _log = Logger("entity.file.file_cache_manager");
