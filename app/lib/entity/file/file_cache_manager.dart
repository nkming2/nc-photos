import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_converter.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/list_util.dart' as list_util;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/touch_token_manager.dart';

class FileCacheLoader {
  FileCacheLoader(
    this._c, {
    required this.cacheSrc,
    required this.remoteSrc,
    this.shouldCheckCache = false,
    this.forwardCacheManager,
  }) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.fileRepo);

  /// Return the cached results of listing a directory [dir]
  ///
  /// Should check [isGood] before using the cache returning by this method
  Future<List<File>?> call(Account account, File dir) async {
    List<File>? cache;
    try {
      if (forwardCacheManager != null) {
        cache = await forwardCacheManager!.list(account, dir);
      } else {
        cache = await cacheSrc.list(account, dir);
      }
      // compare the cached root
      final cacheEtag =
          cache.firstWhere((f) => f.compareServerIdentity(dir)).etag!;
      // compare the etag to see if the content has been updated
      var remoteEtag = dir.etag;
      if (remoteEtag == null) {
        // if no etag supplied, we need to query it form remote
        _log.info(
            "[call] etag missing from input, querying remote: ${logFilename(dir.path)}");
        remoteEtag = (await remoteSrc.list(account, dir, depth: 0)).first.etag;
      }
      if (cacheEtag == remoteEtag) {
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
    final tokenManager = TouchTokenManager(_c);
    String? remoteToken;
    try {
      remoteToken = await tokenManager.getRemoteToken(account, f);
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

  final DiContainer _c;
  final FileWebdavDataSource remoteSrc;
  final FileDataSource cacheSrc;
  final bool shouldCheckCache;
  final FileForwardCacheManager? forwardCacheManager;

  var _isGood = false;
  String? _remoteToken;

  static final _log = Logger("entity.file.file_cache_manager.FileCacheLoader");
}

class FileSqliteCacheUpdater {
  FileSqliteCacheUpdater(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  Future<void> call(
    Account account,
    File dir, {
    required List<File> remote,
  }) async {
    final s = Stopwatch()..start();
    try {
      await _cacheRemote(account, dir, remote);
    } finally {
      _log.info("[call] Elapsed time: ${s.elapsedMilliseconds}ms");
    }
  }

  Future<void> updateSingle(Account account, File remoteFile) async {
    final sqlFile = SqliteFileConverter.toSql(null, remoteFile);
    await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final inserts =
          await _updateCache(db, dbAccount, [sqlFile], [remoteFile], null);
      if (inserts.isNotEmpty) {
        await _insertCache(db, dbAccount, inserts, null);
      }
    });
  }

  Future<void> _cacheRemote(
      Account account, File dir, List<File> remote) async {
    final sqlFiles = await remote.convertToFileCompanion(null);
    await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final inserts = await _updateCache(db, dbAccount, sqlFiles, remote, dir);
      if (inserts.isNotEmpty) {
        await _insertCache(db, dbAccount, inserts, dir);
      }
      if (_dirRowId == null) {
        _log.severe("[_cacheRemote] Dir not inserted");
        throw StateError("Row ID for dir is null");
      }

      final dirChildRowIdQuery = db.selectOnly(db.dirFiles)
        ..addColumns([db.dirFiles.child])
        ..where(db.dirFiles.dir.equals(_dirRowId))
        ..orderBy([sql.OrderingTerm.asc(db.dirFiles.rowId)]);
      final dirChildRowIds =
          await dirChildRowIdQuery.map((r) => r.read(db.dirFiles.child)!).get();
      final diff = list_util.diff(
          dirChildRowIds, _childRowIds.sorted(Comparable.compare));
      if (diff.item1.isNotEmpty) {
        await db.batch((batch) {
          // insert new children
          batch.insertAll(db.dirFiles,
              diff.item1.map((k) => sql.DirFile(dir: _dirRowId!, child: k)));
        });
      }
      if (diff.item2.isNotEmpty) {
        // delete obsolete children
        await _removeSqliteFiles(db, dbAccount, diff.item2);
        await db.cleanUpDanglingFiles();
      }
    });
  }

  /// Update Db files in [sqlFiles]
  ///
  /// Return a list of DB files that are not yet inserted to the DB (thus not
  /// possible to update)
  Future<List<sql.CompleteFileCompanion>> _updateCache(
    sql.SqliteDb db,
    sql.Account dbAccount,
    Iterable<sql.CompleteFileCompanion> sqlFiles,
    Iterable<File> remoteFiles,
    File? dir,
  ) async {
    // query list of rowIds for files in [remoteFiles]
    final rowIds = await db.accountFileRowIdsByFileIds(
      remoteFiles.map((f) => f.fileId!),
      sqlAccount: dbAccount,
    );
    final rowIdsMap = Map.fromEntries(rowIds.map((e) => MapEntry(e.fileId, e)));

    final inserts = <sql.CompleteFileCompanion>[];
    // for updates, we use batch to speed up the process
    await db.batch((batch) {
      for (final f in sqlFiles) {
        final thisRowIds = rowIdsMap[f.file.fileId.value];
        if (thisRowIds != null) {
          // updates
          batch.update(
            db.files,
            f.file,
            where: (sql.$FilesTable t) => t.rowId.equals(thisRowIds.fileRowId),
          );
          batch.update(
            db.accountFiles,
            f.accountFile,
            where: (sql.$AccountFilesTable t) =>
                t.rowId.equals(thisRowIds.accountFileRowId),
          );
          if (f.image != null) {
            batch.update(
              db.images,
              f.image!,
              where: (sql.$ImagesTable t) =>
                  t.accountFile.equals(thisRowIds.accountFileRowId),
            );
          }
          if (f.trash != null) {
            batch.update(
              db.trashes,
              f.trash!,
              where: (sql.$TrashesTable t) =>
                  t.file.equals(thisRowIds.fileRowId),
            );
          }
          _onRowCached(thisRowIds.fileRowId, f, dir);
        } else {
          // inserts, do it later
          inserts.add(f);
        }
      }
    });
    _log.info(
        "[_updateCache] Updated ${sqlFiles.length - inserts.length} files");
    return inserts;
  }

  Future<void> _insertCache(sql.SqliteDb db, sql.Account dbAccount,
      List<sql.CompleteFileCompanion> sqlFiles, File? dir) async {
    _log.info("[_insertCache] Insert ${sqlFiles.length} files");
    // check if the files exist in the db in other accounts
    final entries =
        await sqlFiles.map((f) => f.file.fileId.value).withPartition((sublist) {
      final query = db.queryFiles().run((q) {
        q
          ..setQueryMode(
            sql.FilesQueryMode.expression,
            expressions: [db.files.rowId, db.files.fileId],
          )
          ..setAccountless()
          ..byServerRowId(dbAccount.server)
          ..byFileIds(sublist);
        return q.build();
      });
      return query
          .map((r) =>
              MapEntry(r.read(db.files.fileId)!, r.read(db.files.rowId)!))
          .get();
    }, sql.maxByFileIdsSize);
    final fileRowIdMap = Map.fromEntries(entries);

    await Future.wait(sqlFiles.map((f) async {
      var rowId = fileRowIdMap[f.file.fileId.value];
      if (rowId != null) {
        // shared file that exists in other accounts
      } else {
        final dbFile = await db.into(db.files).insertReturning(
              f.file.copyWith(server: sql.Value(dbAccount.server)),
            );
        rowId = dbFile.rowId;
      }
      final dbAccountFile =
          await db.into(db.accountFiles).insertReturning(f.accountFile.copyWith(
                account: sql.Value(dbAccount.rowId),
                file: sql.Value(rowId),
              ));
      if (f.image != null) {
        await db.into(db.images).insert(
            f.image!.copyWith(accountFile: sql.Value(dbAccountFile.rowId)));
      }
      if (f.trash != null) {
        await db
            .into(db.trashes)
            .insert(f.trash!.copyWith(file: sql.Value(rowId)));
      }
      _onRowCached(rowId, f, dir);
    }));
  }

  void _onRowCached(int rowId, sql.CompleteFileCompanion dbFile, File? dir) {
    if (dir != null) {
      if (_compareIdentity(dbFile, dir)) {
        _dirRowId = rowId;
      }
    }
    _childRowIds.add(rowId);
  }

  bool _compareIdentity(sql.CompleteFileCompanion dbFile, File appFile) {
    if (appFile.fileId != null) {
      return appFile.fileId == dbFile.file.fileId.value;
    } else {
      return appFile.strippedPathWithEmpty ==
          dbFile.accountFile.relativePath.value;
    }
  }

  final DiContainer _c;

  int? _dirRowId;
  final _childRowIds = <int>[];

  static final _log =
      Logger("entity.file.file_cache_manager.FileSqliteCacheUpdater");
}

class FileSqliteCacheRemover {
  FileSqliteCacheRemover(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// Remove a file/dir from cache
  Future<void> call(Account account, File f) async {
    await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final rowIds = await db.accountFileRowIdsOf(f, sqlAccount: dbAccount);
      await _removeSqliteFiles(db, dbAccount, [rowIds.fileRowId]);
      await db.cleanUpDanglingFiles();
    });
  }

  final DiContainer _c;
}

class FileSqliteCacheEmptier {
  FileSqliteCacheEmptier(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// Empty a dir from cache
  Future<void> call(Account account, File dir) async {
    await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final rowIds = await db.accountFileRowIdsOf(dir, sqlAccount: dbAccount);

      // remove children
      final childIdsQuery = db.selectOnly(db.dirFiles)
        ..addColumns([db.dirFiles.child])
        ..where(db.dirFiles.dir.equals(rowIds.fileRowId));
      final childIds =
          await childIdsQuery.map((r) => r.read(db.dirFiles.child)!).get();
      childIds.removeWhere((id) => id == rowIds.fileRowId);
      if (childIds.isNotEmpty) {
        await _removeSqliteFiles(db, dbAccount, childIds);
        await db.cleanUpDanglingFiles();
      }

      // remove dir in DirFiles
      await (db.delete(db.dirFiles)
            ..where((t) => t.dir.equals(rowIds.fileRowId)))
          .go();
    });
  }

  final DiContainer _c;
}

/// Remove a files from the cache db
///
/// If a file is a dir, its children will also be recursively removed
Future<void> _removeSqliteFiles(
    sql.SqliteDb db, sql.Account dbAccount, List<int> fileRowIds) async {
  // query list of children, in case some of the files are dirs
  final childRowIds = await fileRowIds.withPartition((sublist) {
    final childQuery = db.selectOnly(db.dirFiles)
      ..addColumns([db.dirFiles.child])
      ..where(db.dirFiles.dir.isIn(sublist));
    return childQuery.map((r) => r.read(db.dirFiles.child)!).get();
  }, sql.maxByFileIdsSize);
  childRowIds.removeWhere((id) => fileRowIds.contains(id));

  // remove the files in AccountFiles table. We are not removing in Files table
  // because a file could be associated with multiple accounts
  await fileRowIds.withPartitionNoReturn((sublist) async {
    await (db.delete(db.accountFiles)
          ..where(
              (t) => t.account.equals(dbAccount.rowId) & t.file.isIn(sublist)))
        .go();
  }, sql.maxByFileIdsSize);

  if (childRowIds.isNotEmpty) {
    // remove children recursively
    return _removeSqliteFiles(db, dbAccount, childRowIds);
  } else {
    return;
  }
}
