import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/file_cache_manager.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/compat/v32.dart';
import 'package:path/path.dart' as path_lib;
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
    return _listWithArgs(
      account,
      dir,
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
      ownerDisplayName: 1,
      trashbinFilename: 1,
      trashbinOriginalLocation: 1,
      trashbinDeletionTime: 1,
      customNamespaces: {
        "com.nkming.nc_photos": "app",
      },
      customProperties: [
        "app:metadata",
        "app:is-archived",
        "app:override-date-time",
        "app:location",
      ],
    );
  }

  @override
  listSingle(Account account, File f) async {
    _log.info("[listSingle] ${f.path}");
    return (await list(account, f, depth: 0)).first;
  }

  @override
  listMinimal(
    Account account,
    File dir, {
    int? depth,
  }) {
    _log.fine("[listMinimal] ${dir.path}");
    return _listWithArgs(
      account,
      dir,
      depth: depth,
      getlastmodified: 1,
      resourcetype: 1,
      getcontenttype: 1,
      fileid: 1,
    );
  }

  @override
  remove(Account account, File f) async {
    _log.info("[remove] ${f.path}");
    final response = await Api(account).files().delete(path: f.path);
    if (!response.isGood) {
      _log.severe("[remove] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
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
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
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
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
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
    OrNull<ImageLocation>? location,
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
      if (location?.obj != null)
        "app:location": jsonEncode(location!.obj!.toJson()),
    };
    final removeProps = [
      if (OrNull.isSetNull(metadata)) "app:metadata",
      if (OrNull.isSetNull(isArchived)) "app:is-archived",
      if (OrNull.isSetNull(overrideDateTime)) "app:override-date-time",
      if (OrNull.isSetNull(location)) "app:location",
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
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
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
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    } else if (response.statusCode == 204) {
      // conflict
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
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
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
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
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }
  }

  Future<List<File>> _listWithArgs(
    Account account,
    File dir, {
    int? depth,
    getlastmodified,
    getetag,
    getcontenttype,
    resourcetype,
    getcontentlength,
    id,
    fileid,
    favorite,
    commentsHref,
    commentsCount,
    commentsUnread,
    ownerId,
    ownerDisplayName,
    shareTypes,
    checksums,
    hasPreview,
    size,
    richWorkspace,
    trashbinFilename,
    trashbinOriginalLocation,
    trashbinDeletionTime,
    Map<String, String>? customNamespaces,
    List<String>? customProperties,
  }) async {
    final response = await Api(account).files().propfind(
          path: dir.path,
          depth: depth,
          getlastmodified: getlastmodified,
          getetag: getetag,
          getcontenttype: getcontenttype,
          resourcetype: resourcetype,
          getcontentlength: getcontentlength,
          id: id,
          fileid: fileid,
          favorite: favorite,
          commentsHref: commentsHref,
          commentsCount: commentsCount,
          commentsUnread: commentsUnread,
          ownerId: ownerId,
          ownerDisplayName: ownerDisplayName,
          shareTypes: shareTypes,
          checksums: checksums,
          hasPreview: hasPreview,
          size: size,
          richWorkspace: richWorkspace,
          trashbinFilename: trashbinFilename,
          trashbinOriginalLocation: trashbinOriginalLocation,
          trashbinDeletionTime: trashbinDeletionTime,
          customNamespaces: customNamespaces,
          customProperties: customProperties,
        );
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    var files = await WebdavResponseParser().parseFiles(xml);
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

class FileSqliteDbDataSource implements FileDataSource {
  FileSqliteDbDataSource(this._c);

  @override
  list(Account account, File dir) async {
    _log.info("[list] ${dir.path}");
    final dbFiles = await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final sql.File dbDir;
      try {
        dbDir = await db.fileOf(dir, sqlAccount: dbAccount);
      } catch (_) {
        throw CacheNotFoundException("No entry: ${dir.path}");
      }
      return await db.completeFilesByDirRowId(dbDir.rowId,
          sqlAccount: dbAccount);
    });
    final results = (await dbFiles.convertToAppFile(account))
        .where((f) => _validateFile(f))
        .toList();
    _log.fine("[list] Queried ${results.length} files");
    if (results.isEmpty) {
      // each dir will at least contain its own entry, so an empty list here
      // means that the dir has not been queried before
      throw CacheNotFoundException("No entry: ${dir.path}");
    }
    return results;
  }

  @override
  listSingle(Account account, File f) {
    _log.severe("[listSingle] ${f.path}");
    throw UnimplementedError();
  }

  @override
  listMinimal(Account account, File dir) => list(account, dir);

  /// List files with date between [fromEpochMs] (inclusive) and [toEpochMs]
  /// (exclusive)
  Future<List<File>> listByDate(
      Account account, int fromEpochMs, int toEpochMs) async {
    _log.info("[listByDate] [$fromEpochMs, $toEpochMs]");
    final dbFiles = await _c.sqliteDb.use((db) async {
      final query = db.queryFiles().run((q) {
        q.setQueryMode(sql.FilesQueryMode.completeFile);
        q.setAppAccount(account);
        for (final r in account.roots) {
          if (r.isNotEmpty) {
            q.byOrRelativePathPattern("$r/%");
          }
        }
        return q.build();
      });
      final dateTime = db.accountFiles.bestDateTime.secondsSinceEpoch;
      query
        ..where(dateTime.isBetweenValues(
            fromEpochMs ~/ 1000, (toEpochMs ~/ 1000) - 1))
        ..orderBy([sql.OrderingTerm.desc(dateTime)]);
      return await query
          .map((r) => sql.CompleteFile(
                r.readTable(db.files),
                r.readTable(db.accountFiles),
                r.readTableOrNull(db.images),
                r.readTableOrNull(db.imageLocations),
                r.readTableOrNull(db.trashes),
              ))
          .get();
    });
    return await dbFiles.convertToAppFile(account);
  }

  @override
  remove(Account account, File f) {
    _log.info("[remove] ${f.path}");
    return FileSqliteCacheRemover(_c)(account, f);
  }

  @override
  getBinary(Account account, File f) {
    _log.severe("[getBinary] ${f.path}");
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
    OrNull<ImageLocation>? location,
  }) async {
    _log.info("[updateProperty] ${f.path}");
    await _c.sqliteDb.use((db) async {
      final rowIds = await db.accountFileRowIdsOf(f, appAccount: account);
      if (isArchived != null || overrideDateTime != null || favorite != null) {
        final update = sql.AccountFilesCompanion(
          isArchived: isArchived == null
              ? const sql.Value.absent()
              : sql.Value(isArchived.obj),
          overrideDateTime: overrideDateTime == null
              ? const sql.Value.absent()
              : sql.Value(overrideDateTime.obj),
          isFavorite:
              favorite == null ? const sql.Value.absent() : sql.Value(favorite),
          bestDateTime: overrideDateTime == null && metadata == null
              ? const sql.Value.absent()
              : sql.Value(file_util.getBestDateTime(
                  overrideDateTime: overrideDateTime == null
                      ? f.overrideDateTime
                      : overrideDateTime.obj,
                  dateTimeOriginal: metadata == null
                      ? f.metadata?.exif?.dateTimeOriginal
                      : metadata.obj?.exif?.dateTimeOriginal,
                  lastModified: f.lastModified,
                )),
        );
        await (db.update(db.accountFiles)
              ..where((t) => t.rowId.equals(rowIds.accountFileRowId)))
            .write(update);
      }
      if (metadata != null) {
        if (metadata.obj == null) {
          await (db.delete(db.images)
                ..where((t) => t.accountFile.equals(rowIds.accountFileRowId)))
              .go();
        } else {
          await db
              .into(db.images)
              .insertOnConflictUpdate(sql.ImagesCompanion.insert(
                accountFile: sql.Value(rowIds.accountFileRowId),
                lastUpdated: metadata.obj!.lastUpdated,
                fileEtag: sql.Value(metadata.obj!.fileEtag),
                width: sql.Value(metadata.obj!.imageWidth),
                height: sql.Value(metadata.obj!.imageHeight),
                exifRaw: sql.Value(
                    metadata.obj!.exif?.toJson().run((j) => jsonEncode(j))),
                dateTimeOriginal:
                    sql.Value(metadata.obj!.exif?.dateTimeOriginal),
              ));
        }
      }
      if (location != null) {
        if (location.obj == null) {
          await (db.delete(db.imageLocations)
                ..where((t) => t.accountFile.equals(rowIds.accountFileRowId)))
              .go();
        } else {
          await db
              .into(db.imageLocations)
              .insertOnConflictUpdate(sql.ImageLocationsCompanion.insert(
                accountFile: sql.Value(rowIds.accountFileRowId),
                version: location.obj!.version,
                name: sql.Value(location.obj!.name),
                latitude: sql.Value(location.obj!.latitude),
                longitude: sql.Value(location.obj!.longitude),
                countryCode: sql.Value(location.obj!.countryCode),
                admin1: sql.Value(location.obj!.admin1),
                admin2: sql.Value(location.obj!.admin2),
              ));
        }
      }
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

  /// Remove all children of [dir] but not [dir] itself
  Future<void> emptyDir(Account account, File dir) {
    _log.info("[emptyDir] ${dir.path}");
    return FileSqliteCacheEmptier(_c)(account, dir);
  }

  final DiContainer _c;

  static final _log = Logger("entity.file.data_source.FileSqliteDbDataSource");
}

class FileCachedDataSource implements FileDataSource {
  FileCachedDataSource(
    this._c, {
    this.shouldCheckCache = false,
    this.forwardCacheManager,
  }) : _sqliteDbSrc = FileSqliteDbDataSource(_c);

  @override
  list(Account account, File dir) async {
    final cacheLoader = FileCacheLoader(
      _c,
      cacheSrc: _sqliteDbSrc,
      remoteSrc: _remoteSrc,
      shouldCheckCache: shouldCheckCache,
      forwardCacheManager: forwardCacheManager,
    );
    final cache = await cacheLoader(account, dir);
    if (cacheLoader.isGood) {
      return cache!;
    }

    // no cache or outdated
    return await sync(account, dir,
        remoteTouchEtag: cacheLoader.remoteTouchEtag);
  }

  /// Sync [dir] with remote content, and set the local touch etag as
  /// [remoteTouchEtag]
  Future<List<File>> sync(
    Account account,
    File dir, {
    required String? remoteTouchEtag,
  }) async {
    try {
      final remote = await _remoteSrc.list(account, dir);
      await FileSqliteCacheUpdater(_c)(account, dir, remote: remote);
      if (shouldCheckCache) {
        // update our local touch token to match the remote one
        try {
          _log.info("[list] Update outdated local etag: ${dir.path}");
          await _c.touchManager.setLocalEtag(account, dir, remoteTouchEtag);
        } catch (e, stacktrace) {
          _log.shout("[list] Failed while setLocalToken", e, stacktrace);
          // ignore error
        }
      }
      return remote;
    } on ApiException catch (e) {
      if (e.response.statusCode == 404) {
        _log.info("[list] File removed: $dir");
        try {
          await _sqliteDbSrc.remove(account, dir);
        } catch (e) {
          _log.warning(
              "[list] Failed while remove from db, file not cached?", e);
        }
        return [];
      } else if (e.response.statusCode == 403) {
        _log.info("[list] E2E encrypted dir: $dir");
        try {
          // we need to keep the dir itself as it'll be inserted again on next
          // listing of its parent
          await _sqliteDbSrc.emptyDir(account, dir);
        } catch (e) {
          _log.warning(
              "[list] Failed while emptying from db, file not cached?", e);
        }
        return [];
      } else {
        rethrow;
      }
    }
  }

  @override
  listSingle(Account account, File f) async {
    final remote = await _remoteSrc.listSingle(account, f);
    if (remote.isCollection != true) {
      // only update regular files
      _log.info("[listSingle] Cache single file: ${logFilename(f.path)}");
      await FileSqliteCacheUpdater(_c).updateSingle(account, remote);
    }
    return remote;
  }

  @override
  listMinimal(Account account, File dir) {
    return _remoteSrc.listMinimal(account, dir);
  }

  @override
  remove(Account account, File f) async {
    await _sqliteDbSrc.remove(account, f);
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
    OrNull<ImageLocation>? location,
  }) async {
    await _remoteSrc.updateProperty(
      account,
      f,
      metadata: metadata,
      isArchived: isArchived,
      overrideDateTime: overrideDateTime,
      favorite: favorite,
      location: location,
    );
    await _sqliteDbSrc.updateProperty(
      account,
      f,
      metadata: metadata,
      isArchived: isArchived,
      overrideDateTime: overrideDateTime,
      favorite: favorite,
      location: location,
    );

    // generate a new random token
    final dir = File(path: path_lib.dirname(f.path));
    await _c.touchManager.touch(account, dir);
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

  Future<void> flushRemoteTouch() async {
    return _c.touchManager.flushRemote();
  }

  final DiContainer _c;
  final bool shouldCheckCache;
  final FileForwardCacheManager? forwardCacheManager;

  final _remoteSrc = const FileWebdavDataSource();
  final FileSqliteDbDataSource _sqliteDbSrc;

  static final _log = Logger("entity.file.data_source.FileCachedDataSource");
}

/// Forward cache for listing AppDb dirs
///
/// It's very expensive to list a dir and its sub-dirs one by one in multiple
/// queries. This class will instead query every sub-dirs when a new dir is
/// passed to us in one transaction. For this reason, this should only be used
/// when it's necessary to query everything
class FileForwardCacheManager {
  FileForwardCacheManager(this._c, Map<int, File> knownFiles) {
    _fileCache.addAll(knownFiles);
  }

  static bool require(DiContainer c) => true;

  /// Transform a list of files to a map suitable to be passed as the
  /// [knownFiles] argument
  static Map<int, File> prepareFileMap(List<File> knownFiles) => knownFiles
      .where((f) => f.fileId != null)
      .map((e) => MapEntry(e.fileId!, e))
      .run((obj) => Map.fromEntries(obj));

  Future<List<File>> list(Account account, File dir) async {
    // check cache
    var childFileIds = _dirCache[dir.strippedPathWithEmpty];
    if (childFileIds == null) {
      _log.info(
          "[list] No cache and querying everything under ${logFilename(dir.path)}");
      await _cacheDir(account, dir);
      childFileIds = _dirCache[dir.strippedPathWithEmpty];
      if (childFileIds == null) {
        throw CacheNotFoundException("No entry: ${dir.path}");
      }
    } else {
      _log.fine("[list] Returning data from cache: ${logFilename(dir.path)}");
    }
    return _listByFileIds(dir, childFileIds);
  }

  Future<void> _cacheDir(Account account, File dir) async {
    await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final dirCache = <String, List<int>>{};
      await _fillDirCacheForDir(
          db, dirCache, dbAccount, null, dir.fileId, dir.strippedPathWithEmpty);
      _log.info(
          "[_cacheDir] Cached ${dirCache.length} dirs under ${logFilename(dir.path)}");
      await _fillFileCache(
          db, account, dbAccount, dirCache.values.flatten().toSet());
      _dirCache.addAll(dirCache);
    });
  }

  Future<void> _fillDirCacheForDir(
      sql.SqliteDb db,
      Map<String, List<int>> dirCache,
      sql.Account dbAccount,
      int? dirRowId,
      int? dirFileId,
      String dirRelativePath) async {
    // get rowId
    final myDirRowId = dirRowId ??
        await _queryFileIdOfDir(db, dbAccount, dirFileId, dirRelativePath);
    if (myDirRowId == null) {
      // no cache
      return;
    }
    final children = await _queryChildOfDir(db, dbAccount, myDirRowId);
    if (children.isEmpty) {
      // no cache
      return;
    }
    final childFileIds = children.map((c) => c.fileId).toList();
    dirCache[dirRelativePath] = childFileIds;

    // recursively fill child dirs
    for (final c in children
        .where((c) => c.rowId != myDirRowId && c.isCollection == true)) {
      await _fillDirCacheForDir(
          db, dirCache, dbAccount, c.rowId, c.fileId, c.relativePath);
    }
  }

  Future<void> _fillFileCache(sql.SqliteDb db, Account account,
      sql.Account dbAccount, Iterable<int> fileIds) async {
    final needQuery = fileIds.where((id) => !_fileCache.containsKey(id));
    if (needQuery.isNotEmpty) {
      _log.info("[_fillFileCache] ${needQuery.length} files need querying");
      final dbFiles =
          await db.completeFilesByFileIds(needQuery, sqlAccount: dbAccount);
      for (final f in await dbFiles.convertToAppFile(account)) {
        _fileCache[f.fileId!] = f;
      }
      _log.info("[_fillFileCache] Cached ${dbFiles.length} files");
    } else {
      _log.info("[_fillFileCache] 0 files need querying");
    }
  }

  List<File> _listByFileIds(File dir, List<int> childFileIds) {
    return childFileIds.map((id) {
      try {
        return _fileCache[id]!;
      } catch (_) {
        _log.warning(
            "[_listByFileIds] Missing file ($id) in db for dir: ${logFilename(dir.path)}");
        throw CacheNotFoundException("No entry for dir child: $id");
      }
    }).toList();
  }

  Future<int?> _queryFileIdOfDir(sql.SqliteDb db, sql.Account dbAccount,
      int? dirFileId, String dirRelativePath) async {
    final dirQuery = db.queryFiles().run((q) {
      q
        ..setQueryMode(sql.FilesQueryMode.expression,
            expressions: [db.files.rowId])
        ..setSqlAccount(dbAccount);
      if (dirFileId != null) {
        q.byFileId(dirFileId);
      } else {
        q.byRelativePath(dirRelativePath);
      }
      return q.build()..limit(1);
    });
    return await dirQuery.map((r) => r.read(db.files.rowId)).getSingleOrNull();
  }

  Future<List<_ForwardCacheQueryChildResult>> _queryChildOfDir(
      sql.SqliteDb db, sql.Account dbAccount, int dirRowId) async {
    final childQuery = db.selectOnly(db.files).join([
      sql.innerJoin(db.dirFiles, db.dirFiles.child.equalsExp(db.files.rowId),
          useColumns: false),
      sql.innerJoin(
          db.accountFiles, db.accountFiles.file.equalsExp(db.files.rowId),
          useColumns: false),
    ])
      ..addColumns([
        db.files.rowId,
        db.files.fileId,
        db.files.isCollection,
        db.accountFiles.relativePath,
      ])
      ..where(db.dirFiles.dir.equals(dirRowId))
      ..where(db.accountFiles.account.equals(dbAccount.rowId));
    return await childQuery
        .map((r) => _ForwardCacheQueryChildResult(
              r.read(db.files.rowId)!,
              r.read(db.files.fileId)!,
              r.read(db.accountFiles.relativePath)!,
              r.read(db.files.isCollection),
            ))
        .get();
  }

  final DiContainer _c;
  final _dirCache = <String, List<int>>{};
  final _fileCache = <int, File>{};

  static final _log = Logger("entity.file.data_source.FileForwardCacheManager");
}

class _ForwardCacheQueryChildResult {
  const _ForwardCacheQueryChildResult(
      this.rowId, this.fileId, this.relativePath, this.isCollection);

  final int rowId;
  final int fileId;
  final String relativePath;
  final bool? isCollection;
}

bool _validateFile(File f) {
  // See: https://gitlab.com/nkming2/nc-photos/-/issues/9
  return f.lastModified != null;
}
