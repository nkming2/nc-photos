import 'dart:convert';
import 'dart:typed_data';

import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/file_cache_manager.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/touch_token_manager.dart';
import 'package:nc_photos/use_case/compat/v32.dart';
import 'package:path/path.dart' as path_lib;
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

class FileWebdavDataSource implements FileDataSource {
  const FileWebdavDataSource();

  @override
  list(
    Account account,
    File dir, {
    int? depth,
  }) async {
    _log.fine("[list] ${dir.path}");
    final response = await Api(account).files().propfind(
      path: dir.path,
      depth: depth,
      getlastmodified: 1,
      resourcetype: 1,
      getetag: 1,
      getcontenttype: 1,
      getcontentlength: 1,
      hasPreview: 1,
      fileid: 1,
      favorite: 1,
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
    var files = WebdavResponseParser().parseFiles(xml);
    // _log.fine("[list] Parsed files: [$files]");
    bool hasNoMediaMarker = false;
    files = files
        .forEachLazy((f) {
          if (file_util.isNoMediaMarker(f)) {
            hasNoMediaMarker = true;
          }
        })
        .where((f) => _validateFile(f))
        .map((e) {
          if (e.metadata == null || e.metadata!.fileEtag == e.etag) {
            return e;
          } else {
            _log.info("[list] Ignore outdated metadata for ${e.path}");
            return e.copyWith(metadata: OrNull(null));
          }
        })
        .toList();

    await _compatUpgrade(account, files);

    if (hasNoMediaMarker) {
      // return only the marker and the dir itself
      return files
          .where((f) =>
              dir.compareServerIdentity(f) || file_util.isNoMediaMarker(f))
          .toList();
    } else {
      return files;
    }
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
    bool? favorite,
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
      if (favorite != null) "oc:favorite": favorite ? 1 : 0,
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
            "http://owncloud.org/ns": "oc",
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

  /// List files with date between [fromEpochMs] (inclusive) and [toEpochMs]
  /// (exclusive)
  Future<List<File>> listByDate(
      Account account, int fromEpochMs, int toEpochMs) async {
    _log.info("[listByDate] [$fromEpochMs, $toEpochMs]");
    final items = await appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final fileStore = transaction.objectStore(AppDb.file2StoreName);
      final dateTimeEpochMsIndex =
          fileStore.index(AppDbFile2Entry.dateTimeEpochMsIndexName);
      final range = KeyRange.bound(
        AppDbFile2Entry.toDateTimeEpochMsIndexKey(account, fromEpochMs),
        AppDbFile2Entry.toDateTimeEpochMsIndexKey(account, toEpochMs),
        false,
        true,
      );
      return await dateTimeEpochMsIndex.getAll(range);
    });
    return items
        .cast<Map>()
        .map((i) => AppDbFile2Entry.fromJson(i.cast<String, dynamic>()))
        .map((e) => e.file)
        .where((f) => _validateFile(f))
        .toList();
  }

  /// Remove a file/dir from database
  @override
  remove(Account account, File f) {
    _log.info("[remove] ${f.path}");
    return FileCacheRemover(appDb)(account, f);
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
    bool? favorite,
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
        isFavorite: favorite,
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
    this.forwardCacheManager,
  }) : _appDbSrc = FileAppDbDataSource(appDb);

  @override
  list(Account account, File dir) async {
    final cacheLoader = FileCacheLoader(
      appDb: appDb,
      appDbSrc: _appDbSrc,
      remoteSrc: _remoteSrc,
      shouldCheckCache: shouldCheckCache,
      forwardCacheManager: forwardCacheManager,
    );
    final cache = await cacheLoader(account, dir);
    if (cacheLoader.isGood) {
      return cache!;
    }

    // no cache or outdated
    try {
      final remote = await _remoteSrc.list(account, dir);
      await FileCacheUpdater(appDb)(account, dir, remote: remote, cache: cache);
      if (shouldCheckCache) {
        // update our local touch token to match the remote one
        const tokenManager = TouchTokenManager();
        try {
          await tokenManager.setLocalToken(
              account, dir, cacheLoader.remoteTouchToken);
        } catch (e, stacktrace) {
          _log.shout("[list] Failed while setLocalToken", e, stacktrace);
          // ignore error
        }
      }
      return remote;
    } on ApiException catch (e) {
      if (e.response.statusCode == 404) {
        _log.info("[list] File removed: $dir");
        _appDbSrc.remove(account, dir);
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
    bool? favorite,
  }) async {
    await _remoteSrc
        .updateProperty(
          account,
          f,
          metadata: metadata,
          isArchived: isArchived,
          overrideDateTime: overrideDateTime,
          favorite: favorite,
        )
        .then((_) => _appDbSrc.updateProperty(
              account,
              f,
              metadata: metadata,
              isArchived: isArchived,
              overrideDateTime: overrideDateTime,
              favorite: favorite,
            ));

    // generate a new random token
    final token = const Uuid().v4().replaceAll("-", "");
    const tokenManager = TouchTokenManager();
    final dir = File(path: path_lib.dirname(f.path));
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

  final AppDb appDb;
  final bool shouldCheckCache;
  final FileForwardCacheManager? forwardCacheManager;

  final _remoteSrc = const FileWebdavDataSource();
  final FileAppDbDataSource _appDbSrc;

  static final _log = Logger("entity.file.data_source.FileCachedDataSource");
}

/// Forward cache for listing AppDb dirs
///
/// It's very expensive to list a dir and its sub-dirs one by one in multiple
/// queries. This class will instead query every sub-dirs when a new dir is
/// passed to us in one transaction. For this reason, this should only be used
/// when it's necessary to query everything
class FileForwardCacheManager {
  FileForwardCacheManager(this.appDb);

  Future<List<File>> list(Account account, File dir) async {
    // check cache
    final dirKey = AppDbDirEntry.toPrimaryKeyForDir(account, dir);
    final cachedDir = _dirCache[dirKey];
    if (cachedDir != null) {
      _log.fine("[list] Returning data from cache: ${logFilename(dir.path)}");
      return _withDirEntry(cachedDir);
    }
    // no cache, query everything under [dir]
    _log.info(
        "[list] No cache and querying everything under ${logFilename(dir.path)}");
    await _cacheDir(account, dir);
    final cachedDir2 = _dirCache[dirKey];
    if (cachedDir2 == null) {
      throw CacheNotFoundException("No entry: ${dir.path}");
    }
    return _withDirEntry(cachedDir2);
  }

  Future<void> _cacheDir(Account account, File dir) async {
    final dirItems = await appDb.use((db) async {
      final transaction = db.transaction(AppDb.dirStoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.dirStoreName);
      final dirItem = await store
          .getObject(AppDbDirEntry.toPrimaryKeyForDir(account, dir)) as Map?;
      if (dirItem == null) {
        return null;
      }
      final range = KeyRange.bound(
        AppDbDirEntry.toPrimaryLowerKeyForSubDirs(account, dir),
        AppDbDirEntry.toPrimaryUpperKeyForSubDirs(account, dir),
      );
      return [dirItem] + (await store.getAll(range)).cast<Map>();
    });
    if (dirItems == null) {
      // no cache
      return;
    }
    final dirs = dirItems
        .map((i) => AppDbDirEntry.fromJson(i.cast<String, dynamic>()))
        .toList();
    _dirCache.addEntries(dirs.map(
        (e) => MapEntry(AppDbDirEntry.toPrimaryKeyForDir(account, e.dir), e)));
    _log.info(
        "[_cacheDir] Cached ${dirs.length} dirs under ${logFilename(dir.path)}");

    // cache files
    final fileIds = dirs.map((e) => e.children).fold<List<int>>(
        [], (previousValue, element) => previousValue + element);
    final fileItems = await appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.file2StoreName);
      return await Future.wait(fileIds.map(
          (id) => store.getObject(AppDbFile2Entry.toPrimaryKey(account, id))));
    });
    final files = fileItems
        .cast<Map?>()
        .whereType<Map>()
        .map((i) => AppDbFile2Entry.fromJson(i.cast<String, dynamic>()))
        .toList();
    _fileCache.addEntries(files.map((e) => MapEntry(e.file.fileId!, e.file)));
    _log.info(
        "[_cacheDir] Cached ${files.length} files under ${logFilename(dir.path)}");
  }

  List<File> _withDirEntry(AppDbDirEntry dirEntry) {
    return [dirEntry.dir] +
        dirEntry.children.map((id) {
          try {
            return _fileCache[id]!;
          } catch (_) {
            _log.warning(
                "[list] Missing file ($id) in db for dir: ${logFilename(dirEntry.dir.path)}");
            throw CacheNotFoundException("No entry for dir child: $id");
          }
        }).toList();
  }

  final AppDb appDb;
  final _dirCache = <String, AppDbDirEntry>{};
  final _fileCache = <int, File>{};

  static final _log = Logger("entity.file.data_source.FileForwardCacheManager");
}

bool _validateFile(File f) {
  // See: https://gitlab.com/nkming2/nc-photos/-/issues/9
  return f.lastModified != null;
}
