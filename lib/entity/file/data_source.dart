import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/touch_token_manager.dart';
import 'package:nc_photos/use_case/compat/v32.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

class FileWebdavDataSource implements FileDataSource {
  const FileWebdavDataSource();

  @override
  list(
    Account account,
    File f, {
    int? depth,
  }) async {
    _log.fine("[list] ${f.path}");
    final response = await Api(account).files().propfind(
      path: f.path,
      depth: depth,
      getlastmodified: 1,
      resourcetype: 1,
      getetag: 1,
      getcontenttype: 1,
      getcontentlength: 1,
      hasPreview: 1,
      fileid: 1,
      ownerId: 1,
      trashbinFilename: 1,
      trashbinOriginalLocation: 1,
      trashbinDeletionTime: 1,
      customNamespaces: {
        "com.nkming.nc_photos": "app",
      },
      customProperties: [
        "app:metadata",
        "app:is-archived",
        "app:override-date-time"
      ],
    );
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    var files = WebdavFileParser()(xml);
    // _log.fine("[list] Parsed files: [$files]");
    files = files.where((element) => _validateFile(element)).map((e) {
      if (e.metadata == null || e.metadata!.fileEtag == e.etag) {
        return e;
      } else {
        _log.info("[list] Ignore outdated metadata for ${e.path}");
        return e.copyWith(metadata: OrNull(null));
      }
    }).toList();

    await _compatUpgrade(account, files);
    return files;
  }

  @override
  listSingle(Account account, File f) async {
    _log.info("[listSingle] ${f.path}");
    return (await list(account, f, depth: 0)).first;
  }

  @override
  remove(Account account, File f) async {
    _log.info("[remove] ${f.path}");
    final response = await Api(account).files().delete(path: f.path);
    if (!response.isGood) {
      _log.severe("[remove] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  @override
  getBinary(Account account, File f) async {
    _log.info("[getBinary] ${f.path}");
    final response = await Api(account).files().get(path: f.path);
    if (!response.isGood) {
      _log.severe("[getBinary] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
    return response.body;
  }

  @override
  putBinary(Account account, String path, Uint8List content) async {
    _log.info("[putBinary] $path");
    final response =
        await Api(account).files().put(path: path, content: content);
    if (!response.isGood) {
      _log.severe("[putBinary] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  @override
  updateProperty(
    Account account,
    File f, {
    OrNull<Metadata>? metadata,
    OrNull<bool>? isArchived,
    OrNull<DateTime>? overrideDateTime,
  }) async {
    _log.info("[updateProperty] ${f.path}");
    if (metadata?.obj != null && metadata!.obj!.fileEtag != f.etag) {
      _log.warning(
          "[updateProperty] Metadata etag mismatch (metadata: ${metadata.obj!.fileEtag}, file: ${f.etag})");
    }
    final setProps = {
      if (metadata?.obj != null)
        "app:metadata": jsonEncode(metadata!.obj!.toJson()),
      if (isArchived?.obj != null) "app:is-archived": isArchived!.obj,
      if (overrideDateTime?.obj != null)
        "app:override-date-time":
            overrideDateTime!.obj!.toUtc().toIso8601String(),
    };
    final removeProps = [
      if (OrNull.isSetNull(metadata)) "app:metadata",
      if (OrNull.isSetNull(isArchived)) "app:is-archived",
      if (OrNull.isSetNull(overrideDateTime)) "app:override-date-time",
    ];
    final response = await Api(account).files().proppatch(
          path: f.path,
          namespaces: {
            "com.nkming.nc_photos": "app",
          },
          set: setProps.isNotEmpty ? setProps : null,
          remove: removeProps.isNotEmpty ? removeProps : null,
        );
    if (!response.isGood) {
      _log.severe("[updateProperty] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  @override
  copy(
    Account account,
    File f,
    String destination, {
    bool? shouldOverwrite,
  }) async {
    _log.info("[copy] ${f.path} to $destination");
    final response = await Api(account).files().copy(
          path: f.path,
          destinationUrl: "${account.url}/$destination",
          overwrite: shouldOverwrite,
        );
    if (!response.isGood) {
      _log.severe("[copy] Failed requesting sever: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    } else if (response.statusCode == 204) {
      // conflict
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  @override
  move(
    Account account,
    File f,
    String destination, {
    bool? shouldOverwrite,
  }) async {
    _log.info("[move] ${f.path} to $destination");
    final response = await Api(account).files().move(
          path: f.path,
          destinationUrl: "${account.url}/$destination",
          overwrite: shouldOverwrite,
        );
    if (!response.isGood) {
      _log.severe("[move] Failed requesting sever: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  @override
  createDir(Account account, String path) async {
    _log.info("[createDir] $path");
    final response = await Api(account).files().mkcol(
          path: path,
        );
    if (!response.isGood) {
      _log.severe("[createDir] Failed requesting sever: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  Future<void> _compatUpgrade(Account account, List<File> files) async {
    for (final f in files.where((element) => element.metadata?.exif != null)) {
      if (CompatV32.isExifNeedMigration(f.metadata!.exif!)) {
        final newExif = CompatV32.migrateExif(f.metadata!.exif!, f.path);
        await updateProperty(
          account,
          f,
          metadata: OrNull(f.metadata!.copyWith(
            exif: newExif,
          )),
        );
      }
    }
  }

  static final _log = Logger("entity.file.data_source.FileWebdavDataSource");
}

class FileAppDbDataSource implements FileDataSource {
  const FileAppDbDataSource(this.appDb);

  @override
  list(Account account, File dir) {
    _log.info("[list] ${dir.path}");
    return appDb.use((db) async {
      final transaction = db.transaction(
          [AppDb.dirStoreName, AppDb.file2StoreName], idbModeReadOnly);
      final fileStore = transaction.objectStore(AppDb.file2StoreName);
      final dirStore = transaction.objectStore(AppDb.dirStoreName);
      final dirItem = await dirStore
          .getObject(AppDbDirEntry.toPrimaryKeyForDir(account, dir)) as Map?;
      if (dirItem == null) {
        throw CacheNotFoundException("No entry: ${dir.path}");
      }
      final dirEntry = AppDbDirEntry.fromJson(dirItem.cast<String, dynamic>());
      final entries = await Future.wait(dirEntry.children.map((c) async {
        final fileItem = await fileStore
            .getObject(AppDbFile2Entry.toPrimaryKey(account, c)) as Map?;
        if (fileItem == null) {
          _log.warning(
              "[list] Missing file ($c) in db for dir: ${logFilename(dir.path)}");
          throw CacheNotFoundException("No entry for dir child: $c");
        }
        return AppDbFile2Entry.fromJson(fileItem.cast<String, dynamic>());
      }));
      // we need to add dir to match the remote query
      return [dirEntry.dir] +
          entries.map((e) => e.file).where((f) => _validateFile(f)).toList();
    });
  }

  @override
  listSingle(Account account, File f) {
    _log.info("[listSingle] ${f.path}");
    throw UnimplementedError();
  }

  /// Remove a file/dir from database
  ///
  /// If [f] is a dir, the dir and its sub-dirs will be removed from dirStore.
  /// The files inside any of these dirs will be removed from file2Store.
  ///
  /// If [f] is a file, the file will be removed from file2Store, but no changes
  /// to dirStore.
  @override
  remove(Account account, File f) async {
    _log.info("[remove] ${f.path}");
    await appDb.use((db) async {
      if (f.isCollection == true) {
        final transaction = db.transaction(
            [AppDb.dirStoreName, AppDb.file2StoreName], idbModeReadWrite);
        final dirStore = transaction.objectStore(AppDb.dirStoreName);
        final fileStore = transaction.objectStore(AppDb.file2StoreName);
        await _removeDirFromAppDb(account, f,
            dirStore: dirStore, fileStore: fileStore);
      } else {
        final transaction =
            db.transaction(AppDb.file2StoreName, idbModeReadWrite);
        final fileStore = transaction.objectStore(AppDb.file2StoreName);
        await _removeFileFromAppDb(account, f, fileStore: fileStore);
      }
    });
  }

  @override
  getBinary(Account account, File f) {
    _log.info("[getBinary] ${f.path}");
    throw UnimplementedError();
  }

  @override
  putBinary(Account account, String path, Uint8List content) async {
    _log.info("[putBinary] $path");
    // do nothing, we currently don't store file contents locally
  }

  @override
  updateProperty(
    Account account,
    File f, {
    OrNull<Metadata>? metadata,
    OrNull<bool>? isArchived,
    OrNull<DateTime>? overrideDateTime,
  }) {
    _log.info("[updateProperty] ${f.path}");
    return appDb.use((db) async {
      final transaction =
          db.transaction(AppDb.file2StoreName, idbModeReadWrite);

      // update file store
      final newFile = f.copyWith(
        metadata: metadata,
        isArchived: isArchived,
        overrideDateTime: overrideDateTime,
      );
      final fileStore = transaction.objectStore(AppDb.file2StoreName);
      await fileStore.put(AppDbFile2Entry.fromFile(account, newFile).toJson(),
          AppDbFile2Entry.toPrimaryKeyForFile(account, newFile));
    });
  }

  @override
  copy(
    Account account,
    File f,
    String destination, {
    bool? shouldOverwrite,
  }) async {
    // do nothing
  }

  @override
  move(
    Account account,
    File f,
    String destination, {
    bool? shouldOverwrite,
  }) async {
    // do nothing
  }

  @override
  createDir(Account account, String path) async {
    // do nothing
  }

  final AppDb appDb;

  static final _log = Logger("entity.file.data_source.FileAppDbDataSource");
}

class FileCachedDataSource implements FileDataSource {
  FileCachedDataSource(
    this.appDb, {
    this.shouldCheckCache = false,
  }) : _appDbSrc = FileAppDbDataSource(appDb);

  @override
  list(Account account, File f) async {
    final cacheManager = _CacheManager(
      appDb: appDb,
      appDbSrc: _appDbSrc,
      remoteSrc: _remoteSrc,
      shouldCheckCache: shouldCheckCache,
    );
    final cache = await cacheManager.list(account, f);
    if (cacheManager.isGood) {
      return cache!;
    }

    // no cache or outdated
    try {
      final remote = await _remoteSrc.list(account, f);
      await _cacheResult(account, f, remote);
      if (shouldCheckCache) {
        // update our local touch token to match the remote one
        final tokenManager = TouchTokenManager();
        try {
          await tokenManager.setLocalToken(
              account, f, cacheManager.remoteTouchToken);
        } catch (e, stacktrace) {
          _log.shout("[list] Failed while setLocalToken", e, stacktrace);
          // ignore error
        }
      }

      if (cache != null) {
        await _cleanUpCacheWithRemote(account, remote, cache);
      }
      return remote;
    } on ApiException catch (e) {
      if (e.response.statusCode == 404) {
        _log.info("[list] File removed: $f");
        _appDbSrc.remove(account, f);
        return [];
      } else {
        rethrow;
      }
    }
  }

  @override
  listSingle(Account account, File f) {
    return _remoteSrc.listSingle(account, f);
  }

  @override
  remove(Account account, File f) async {
    await _appDbSrc.remove(account, f);
    await _remoteSrc.remove(account, f);
  }

  @override
  getBinary(Account account, File f) {
    return _remoteSrc.getBinary(account, f);
  }

  @override
  putBinary(Account account, String path, Uint8List content) async {
    await _remoteSrc.putBinary(account, path, content);
  }

  @override
  updateProperty(
    Account account,
    File f, {
    OrNull<Metadata>? metadata,
    OrNull<bool>? isArchived,
    OrNull<DateTime>? overrideDateTime,
  }) async {
    await _remoteSrc
        .updateProperty(
          account,
          f,
          metadata: metadata,
          isArchived: isArchived,
          overrideDateTime: overrideDateTime,
        )
        .then((_) => _appDbSrc.updateProperty(
              account,
              f,
              metadata: metadata,
              isArchived: isArchived,
              overrideDateTime: overrideDateTime,
            ));

    // generate a new random token
    final token = const Uuid().v4().replaceAll("-", "");
    final tokenManager = TouchTokenManager();
    final dir = File(path: path.dirname(f.path));
    await tokenManager.setLocalToken(account, dir, token);
    final fileRepo = FileRepo(this);
    await tokenManager.setRemoteToken(fileRepo, account, dir, token);
    _log.info(
        "[updateMetadata] New touch token '$token' for dir '${dir.path}'");
  }

  @override
  copy(
    Account account,
    File f,
    String destination, {
    bool? shouldOverwrite,
  }) async {
    await _remoteSrc.copy(account, f, destination,
        shouldOverwrite: shouldOverwrite);
  }

  @override
  move(
    Account account,
    File f,
    String destination, {
    bool? shouldOverwrite,
  }) async {
    await _remoteSrc.move(account, f, destination,
        shouldOverwrite: shouldOverwrite);
  }

  @override
  createDir(Account account, String path) async {
    await _remoteSrc.createDir(account, path);
  }

  Future<void> _cacheResult(Account account, File f, List<File> result) {
    return appDb.use((db) async {
      final transaction = db.transaction(
          [AppDb.dirStoreName, AppDb.file2StoreName], idbModeReadWrite);
      final dirStore = transaction.objectStore(AppDb.dirStoreName);
      final fileStore = transaction.objectStore(AppDb.file2StoreName);
      await _cacheListResults(account, f, result,
          fileStore: fileStore, dirStore: dirStore);
    });
  }

  /// Remove extra entries from local cache based on remote results
  Future<void> _cleanUpCacheWithRemote(
      Account account, List<File> remote, List<File> cache) async {
    final removed =
        cache.where((c) => !remote.any((r) => r.path == c.path)).toList();
    if (removed.isEmpty) {
      return;
    }
    _log.info(
        "[_cleanUpCacheWithRemote] Removed: ${removed.map((f) => f.path).toReadableString()}");

    await appDb.use((db) async {
      final transaction = db.transaction(
          [AppDb.dirStoreName, AppDb.file2StoreName], idbModeReadWrite);
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
              "[_cleanUpCacheWithRemote] Failed while removing file: ${logFilename(f.path)}",
              e,
              stackTrace);
        }
      }
    });
  }

  final AppDb appDb;
  final bool shouldCheckCache;

  final _remoteSrc = const FileWebdavDataSource();
  final FileAppDbDataSource _appDbSrc;

  static final _log = Logger("entity.file.data_source.FileCachedDataSource");
}

class _CacheManager {
  _CacheManager({
    required this.appDb,
    required this.appDbSrc,
    required this.remoteSrc,
    this.shouldCheckCache = false,
  });

  /// Return the cached results of listing a directory [dir]
  ///
  /// Should check [isGood] before using the cache returning by this method
  Future<List<File>?> list(Account account, File dir) async {
    List<File>? cache;
    try {
      cache = await appDbSrc.list(account, dir);
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
        _log.info("[list] Remote content updated for ${dir.path}");
      }
    } on CacheNotFoundException catch (_) {
      // normal when there's no cache
    } catch (e, stackTrace) {
      _log.shout("[list] Cache failure", e, stackTrace);
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
    final tokenManager = TouchTokenManager();
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

  var _isGood = false;
  String? _remoteToken;

  static final _log = Logger("entity.file.data_source._CacheManager");
}

Future<void> _cacheListResults(
  Account account,
  File dir,
  List<File> results, {
  required ObjectStore fileStore,
  required ObjectStore dirStore,
}) async {
  // add files to db
  await Future.wait(results.map((f) => fileStore.put(
      AppDbFile2Entry.fromFile(account, f).toJson(),
      AppDbFile2Entry.toPrimaryKeyForFile(account, f))));

  // results from remote also contain the dir itself
  final resultGroup = results.groupListsBy((f) => f.compareServerIdentity(dir));
  final remoteDir = resultGroup[true]!.first;
  final remoteChildren = resultGroup[false] ?? [];
  // add dir to db
  await dirStore.put(
      AppDbDirEntry.fromFiles(account, remoteDir, remoteChildren).toJson(),
      AppDbDirEntry.toPrimaryKeyForDir(account, remoteDir));
}

Future<void> _removeFileFromAppDb(
  Account account,
  File file, {
  required ObjectStore fileStore,
}) async {
  assert(file.isCollection != true);
  await fileStore.delete(AppDbFile2Entry.toPrimaryKeyForFile(account, file));
}

/// Remove a dir and all files inside from the database
Future<void> _removeDirFromAppDb(
  Account account,
  File dir, {
  required ObjectStore dirStore,
  required ObjectStore fileStore,
}) async {
  assert(dir.isCollection == true);
  // delete the dir itself
  await AppDbDirEntry.toPrimaryKeyForDir(account, dir).runFuture((key) async {
    _log.fine("[_removeDirFromAppDb] Removing dirStore entry: $key");
    await dirStore.delete(key);
  });
  // then its children
  final childrenRange = KeyRange.bound(
    AppDbDirEntry.toPrimaryLowerKeyForSubDirs(account, dir),
    AppDbDirEntry.toPrimaryUpperKeyForSubDirs(account, dir),
  );
  for (final key in await dirStore.getAllKeys(childrenRange)) {
    _log.fine("[_removeDirFromAppDb] Removing dirStore entry: $key");
    await dirStore.delete(key);
  }

  // delete files from fileStore
  // first the dir
  await AppDbFile2Entry.toPrimaryKeyForFile(account, dir)
      .runFuture((key) async {
    _log.fine("[_removeDirFromAppDb] Removing fileStore entry: $key");
    await fileStore.delete(key);
  });
  // then files under this dir and sub-dirs
  final range = KeyRange.bound(
    AppDbFile2Entry.toStrippedPathIndexLowerKeyForDir(account, dir),
    AppDbFile2Entry.toStrippedPathIndexUpperKeyForDir(account, dir),
  );
  final strippedPathIndex =
      fileStore.index(AppDbFile2Entry.strippedPathIndexName);
  for (final key in await strippedPathIndex.getAllKeys(range)) {
    _log.fine("[_removeDirFromAppDb] Removing fileStore entry: $key");
    await fileStore.delete(key);
  }
}

bool _validateFile(File f) {
  // See: https://gitlab.com/nkming2/nc-photos/-/issues/9
  return f.lastModified != null;
}

final _log = Logger("entity.file.data_source");
