import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/int_util.dart' as int_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/string_extension.dart';
import 'package:nc_photos/touch_token_manager.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/iterables.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

class FileWebdavDataSource implements FileDataSource {
  @override
  list(
    Account account,
    File f, {
    int depth,
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
      customNamespaces: {
        "com.nkming.nc_photos": "app",
      },
      customProperties: [
        "app:metadata",
        "app:is-archived",
      ],
    );
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    final files = WebdavFileParser()(xml);
    // _log.fine("[list] Parsed files: [$files]");
    return files.map((e) {
      if (e.metadata == null || e.metadata.fileEtag == e.etag) {
        return e;
      } else {
        _log.info("[list] Ignore outdated metadata for ${e.path}");
        return e.copyWith(metadata: OrNull(null));
      }
    }).toList();
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
    OrNull<Metadata> metadata,
    OrNull<bool> isArchived,
  }) async {
    _log.info("[updateProperty] ${f.path}");
    if (metadata?.obj != null && metadata.obj.fileEtag != f.etag) {
      _log.warning(
          "[updateProperty] Metadata etag mismatch (metadata: ${metadata.obj.fileEtag}, file: ${f.etag})");
    }
    final setProps = {
      if (metadata?.obj != null)
        "app:metadata": jsonEncode(metadata.obj.toJson()),
      if (isArchived?.obj != null) "app:is-archived": isArchived.obj,
    };
    final removeProps = [
      if (OrNull.isNull(metadata)) "app:metadata",
      if (OrNull.isNull(isArchived)) "app:is-archived",
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
    bool shouldOverwrite,
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
    }
  }

  @override
  move(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
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

  static final _log = Logger("entity.file.data_source.FileWebdavDataSource");
}

class FileAppDbDataSource implements FileDataSource {
  @override
  list(Account account, File f) {
    _log.info("[list] ${f.path}");
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.fileStoreName);
      return await _doList(store, account, f);
    });
  }

  @override
  remove(Account account, File f) {
    _log.info("[remove] ${f.path}");
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.fileStoreName);
      final index = store.index(AppDbFileEntry.indexName);
      final path = AppDbFileEntry.toPath(account, f);
      final range = KeyRange.bound([path, 0], [path, int_util.int32Max]);
      final keys = await index
          .openKeyCursor(range: range, autoAdvance: true)
          .map((cursor) => cursor.primaryKey)
          .toList();
      for (final k in keys) {
        _log.fine("[remove] Removing DB entry: $k");
        await store.delete(k);
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
    OrNull<Metadata> metadata,
    OrNull<bool> isArchived,
  }) {
    _log.info("[updateProperty] ${f.path}");
    return AppDb.use((db) async {
      final transaction = db.transaction(
          [AppDb.fileStoreName, AppDb.fileDbStoreName], idbModeReadWrite);

      // update file store
      final fileStore = transaction.objectStore(AppDb.fileStoreName);
      final parentDir = File(path: path.dirname(f.path));
      final parentList = await _doList(fileStore, account, parentDir);
      final jsonList = parentList.map((e) {
        if (e.path == f.path) {
          return e.copyWith(
            metadata: metadata,
            isArchived: isArchived,
          );
        } else {
          return e;
        }
      });
      await _cacheListResults(fileStore, account, parentDir, jsonList);

      // update file db store
      final fileDbStore = transaction.objectStore(AppDb.fileDbStoreName);
      final newFile = f.copyWith(
        metadata: metadata,
        isArchived: isArchived,
      );
      await fileDbStore.put(
          AppDbFileDbEntry.fromFile(account, newFile).toJson(),
          AppDbFileDbEntry.toPrimaryKey(account, newFile));
    });
  }

  @override
  copy(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
  }) async {
    // do nothing
  }

  @override
  move(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
  }) async {
    // do nothing
  }

  @override
  createDir(Account account, String path) async {
    // do nothing
  }

  Future<List<File>> _doList(ObjectStore store, Account account, File f) async {
    final index = store.index(AppDbFileEntry.indexName);
    final path = AppDbFileEntry.toPath(account, f);
    final range = KeyRange.bound([path, 0], [path, int_util.int32Max]);
    final List results = await index.getAll(range);
    if (results?.isNotEmpty == true) {
      final entries = results
          .map((e) => AppDbFileEntry.fromJson(e.cast<String, dynamic>()));
      return entries.map((e) {
        _log.info("[_doList] ${e.path}[${e.index}]");
        return e.data;
      }).reduce((value, element) => value + element);
    } else {
      throw CacheNotFoundException("No entry: $path");
    }
  }

  static final _log = Logger("entity.file.data_source.FileAppDbDataSource");
}

class FileCachedDataSource implements FileDataSource {
  FileCachedDataSource({
    this.shouldCheckCache = false,
  });

  @override
  list(Account account, File f) async {
    final cacheManager = _CacheManager(
      appDbSrc: _appDbSrc,
      remoteSrc: _remoteSrc,
      shouldCheckCache: shouldCheckCache,
    );
    final cache = await cacheManager.list(account, f);
    if (cacheManager.isGood) {
      return cache;
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
        _syncCacheWithRemote(account, remote, cache);
      } else {
        AppDb.use((db) async {
          final transaction =
              db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
          final fileDbStore = transaction.objectStore(AppDb.fileDbStoreName);
          for (final f in remote) {
            try {
              await _upsertFileDbStoreCache(account, f, fileDbStore);
            } catch (e, stacktrace) {
              _log.shout(
                  "[list] Failed while _upsertFileDbStoreCache", e, stacktrace);
            }
          }
        });
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
    OrNull<Metadata> metadata,
    OrNull<bool> isArchived,
  }) async {
    await _remoteSrc
        .updateProperty(
          account,
          f,
          metadata: metadata,
          isArchived: isArchived,
        )
        .then((_) => _appDbSrc.updateProperty(
              account,
              f,
              metadata: metadata,
              isArchived: isArchived,
            ));

    // generate a new random token
    final token = Uuid().v4().replaceAll("-", "");
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
    bool shouldOverwrite,
  }) async {
    await _remoteSrc.copy(account, f, destination,
        shouldOverwrite: shouldOverwrite);
  }

  @override
  move(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
  }) async {
    await _remoteSrc.move(account, f, destination,
        shouldOverwrite: shouldOverwrite);
  }

  @override
  createDir(Account account, String path) async {
    await _remoteSrc.createDir(account, path);
  }

  Future<void> _cacheResult(Account account, File f, List<File> result) {
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.fileStoreName);
      await _cacheListResults(store, account, f, result);
    });
  }

  /// Sync the remote result and local cache
  void _syncCacheWithRemote(
      Account account, List<File> remote, List<File> cache) async {
    final removed =
        cache.where((c) => !remote.any((r) => r.path == c.path)).toList();
    _log.info(
        "[_syncCacheWithRemote] Removed: ${removed.map((f) => f.path).toReadableString()}");

    AppDb.use((db) async {
      final transaction = db.transaction(
          [AppDb.fileStoreName, AppDb.fileDbStoreName], idbModeReadWrite);
      final fileStore = transaction.objectStore(AppDb.fileStoreName);
      final fileStoreIndex = fileStore.index(AppDbFileEntry.indexName);
      final fileDbStore = transaction.objectStore(AppDb.fileDbStoreName);
      for (final f in removed) {
        try {
          await _removeFileDbStoreCache(account, f, fileDbStore);
        } catch (e, stacktrace) {
          _log.shout(
              "[_syncCacheWithRemote] Failed while _removeFileDbStoreCache",
              e,
              stacktrace);
        }
        try {
          await _removeFileStoreCache(account, f, fileStore, fileStoreIndex);
        } catch (e, stacktrace) {
          _log.shout(
              "[_syncCacheWithRemote] Failed while _removeFileStoreCache",
              e,
              stacktrace);
        }
      }
      for (final f in remote) {
        try {
          await _upsertFileDbStoreCache(account, f, fileDbStore);
        } catch (e, stacktrace) {
          _log.shout(
              "[_syncCacheWithRemote] Failed while _upsertFileDbStoreCache",
              e,
              stacktrace);
        }
      }
    });
  }

  Future<void> _removeFileDbStoreCache(
      Account account, File file, ObjectStore objStore) async {
    if (file.isCollection == true) {
      final fullPath = AppDbFileDbEntry.toPrimaryKey(account, file);
      final range = KeyRange.bound("$fullPath/", "$fullPath/\uffff");
      await for (final k
          in objStore.openKeyCursor(range: range, autoAdvance: true)) {
        _log.fine(
            "[_removeFileDbStoreCache] Removing DB entry: ${k.primaryKey}");
        objStore.delete(k.primaryKey);
      }
    } else {
      await objStore.delete(AppDbFileDbEntry.toPrimaryKey(account, file));
    }
  }

  Future<void> _upsertFileDbStoreCache(
      Account account, File file, ObjectStore objStore) async {
    if (file.isCollection == true) {
      return;
    }
    await objStore.put(AppDbFileDbEntry.fromFile(account, file).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file));
  }

  /// Remove dangling dir entries in the file object store
  Future<void> _removeFileStoreCache(
      Account account, File file, ObjectStore objStore, Index index) async {
    if (file.isCollection != true) {
      return;
    }

    final path = AppDbFileEntry.toPath(account, file);
    // delete the dir itself
    final dirRange = KeyRange.bound([path, 0], [path, int_util.int32Max]);
    // delete with KeyRange is not supported in idb_shim/idb_sqflite
    // await store.delete(dirRange);
    await for (final k
        in index.openKeyCursor(range: dirRange, autoAdvance: true)) {
      _log.fine("[_removeFileStoreCache] Removing DB entry: ${k.primaryKey}");
      objStore.delete(k.primaryKey);
    }
    // then its children
    final childrenRange =
        KeyRange.bound(["$path/", 0], ["$path/\uffff", int_util.int32Max]);
    await for (final k
        in index.openKeyCursor(range: childrenRange, autoAdvance: true)) {
      _log.fine("[_removeFileStoreCache] Removing DB entry: ${k.primaryKey}");
      objStore.delete(k.primaryKey);
    }
  }

  final bool shouldCheckCache;

  final _remoteSrc = FileWebdavDataSource();
  final _appDbSrc = FileAppDbDataSource();

  static final _log = Logger("entity.file.data_source.FileCachedDataSource");
}

class _CacheManager {
  _CacheManager({
    @required this.appDbSrc,
    @required this.remoteSrc,
    this.shouldCheckCache = false,
  });

  /// Return the cached results of listing a directory [f]
  ///
  /// Should check [isGood] before using the cache returning by this method
  Future<List<File>> list(Account account, File f) async {
    final trimmedRootPath = f.path.trimAny("/");
    List<File> cache;
    try {
      cache = await appDbSrc.list(account, f);
      // compare the cached root
      final cacheEtag = cache
          .firstWhere((element) => element.path.trimAny("/") == trimmedRootPath)
          .etag;
      if (cacheEtag != null) {
        // compare the etag to see if the content has been updated
        var remoteEtag = f.etag;
        if (remoteEtag == null) {
          // no etag supplied, we need to query it form remote
          final remote = await remoteSrc.list(account, f, depth: 0);
          assert(remote.length == 1);
          remoteEtag = remote.first.etag;
        }
        if (cacheEtag == remoteEtag) {
          _log.fine(
              "[_listCache] etag matched for ${AppDbFileEntry.toPath(account, f)}");
          if (shouldCheckCache) {
            await _checkTouchToken(account, f, cache);
          } else {
            _isGood = true;
          }
        }
      } else {
        _log.info(
            "[_list] Remote content updated for ${AppDbFileEntry.toPath(account, f)}");
      }
    } on CacheNotFoundException catch (_) {
      // normal when there's no cache
    } catch (e, stacktrace) {
      _log.shout("[_list] Cache failure", e, stacktrace);
    }
    return cache;
  }

  bool get isGood => _isGood;
  String get remoteTouchToken => _remoteToken;

  Future<void> _checkTouchToken(
      Account account, File f, List<File> cache) async {
    final touchPath =
        "${remote_storage_util.getRemoteTouchDir(account)}/${f.strippedPath}";
    final fileRepo = FileRepo(FileCachedDataSource());
    final tokenManager = TouchTokenManager();
    String remoteToken;
    try {
      remoteToken = await tokenManager.getRemoteToken(fileRepo, account, f);
    } catch (e, stacktrace) {
      _log.shout(
          "[_checkTouchToken] Failed getting remote token at '$touchPath'",
          e,
          stacktrace);
    }
    _remoteToken = remoteToken;

    String localToken;
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

  final FileWebdavDataSource remoteSrc;
  final FileAppDbDataSource appDbSrc;
  final bool shouldCheckCache;

  var _isGood = false;
  String _remoteToken;

  static final _log = Logger("entity.file.data_source._CacheManager");
}

Future<void> _cacheListResults(
    ObjectStore store, Account account, File f, Iterable<File> results) async {
  final index = store.index(AppDbFileEntry.indexName);
  final path = AppDbFileEntry.toPath(account, f);
  final range = KeyRange.bound([path, 0], [path, int_util.int32Max]);
  // count number of entries for this dir
  final count = await index.count(range);
  int newCount = 0;
  for (final pair
      in partition(results, AppDbFileEntry.maxDataSize).withIndex()) {
    _log.info(
        "[_cacheListResults] Caching $path[${pair.item1}], length: ${pair.item2.length}");
    await store.put(
      AppDbFileEntry(path, pair.item1, pair.item2).toJson(),
      AppDbFileEntry.toPrimaryKey(account, f, pair.item1),
    );
    ++newCount;
  }
  if (count > newCount) {
    // index is 0-based
    final rmRange = KeyRange.bound([path, newCount], [path, int_util.int32Max]);
    final rmKeys = await index
        .openKeyCursor(range: rmRange, autoAdvance: true)
        .map((cursor) => cursor.primaryKey)
        .toList();
    for (final k in rmKeys) {
      _log.fine("[_cacheListResults] Removing DB entry: $k");
      await store.delete(k);
    }
  }
}

final _log = Logger("entity.file.data_source");
