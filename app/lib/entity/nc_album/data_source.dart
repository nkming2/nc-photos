import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/entity_converter.dart';
import 'package:nc_photos/entity/nc_album.dart';
import 'package:nc_photos/entity/nc_album/item.dart';
import 'package:nc_photos/entity/nc_album/repo.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/list_util.dart' as list_util;
import 'package:nc_photos/np_api_util.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_codegen/np_codegen.dart';

part 'data_source.g.dart';

@npLog
class NcAlbumRemoteDataSource implements NcAlbumDataSource {
  const NcAlbumRemoteDataSource();

  @override
  Future<List<NcAlbum>> getAlbums(Account account) async {
    _log.info("[getAlbums] account: ${account.userId}");
    final response = await ApiUtil.fromAccount(account)
        .photos(account.userId.toString())
        .albums()
        .propfind(
          lastPhoto: 1,
          nbItems: 1,
          location: 1,
          dateRange: 1,
          collaborators: 1,
        );
    if (!response.isGood) {
      _log.severe("[getAlbums] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }

    final apiNcAlbums = await api.NcAlbumParser().parse(response.body);
    return apiNcAlbums
        .map(ApiNcAlbumConverter.fromApi)
        .where((a) => a.strippedPath != ".")
        .toList();
  }

  @override
  Future<void> create(Account account, NcAlbum album) async {
    _log.info("[create] account: ${account.userId}, album: ${album.path}");
    final response = await ApiUtil.fromAccount(account)
        .photos(account.userId.toString())
        .album(album.strippedPath)
        .mkcol();
    if (!response.isGood) {
      _log.severe("[create] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }
  }

  @override
  Future<void> remove(Account account, NcAlbum album) async {
    _log.info("[remove] account: ${account.userId}, album: ${album.path}");
    final response = await ApiUtil.fromAccount(account)
        .photos(account.userId.toString())
        .album(album.strippedPath)
        .delete();
    if (!response.isGood) {
      _log.severe("[remove] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }
  }

  @override
  Future<List<NcAlbumItem>> getItems(Account account, NcAlbum album) async {
    _log.info(
        "[getItems] account: ${account.userId}, album: ${album.strippedPath}");
    final response = await ApiUtil.fromAccount(account).files().propfind(
          path: album.path,
          fileid: 1,
        );
    if (!response.isGood) {
      _log.severe("[getItems] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }

    final apiFiles = await api.FileParser().parse(response.body);
    return apiFiles
        .where((f) => f.fileId != null)
        .map(ApiFileConverter.fromApi)
        .map((f) => NcAlbumItem(f.fileId!))
        .toList();
  }
}

@npLog
class NcAlbumSqliteDbDataSource implements NcAlbumCacheDataSource {
  const NcAlbumSqliteDbDataSource(this.sqliteDb);

  @override
  Future<List<NcAlbum>> getAlbums(Account account) async {
    _log.info("[getAlbums] account: ${account.userId}");
    final dbAlbums = await sqliteDb.use((db) async {
      return await db.ncAlbumsByAccount(account: sql.ByAccount.app(account));
    });
    return dbAlbums
        .map((a) {
          try {
            return SqliteNcAlbumConverter.fromSql(account.userId.toString(), a);
          } catch (e, stackTrace) {
            _log.severe(
                "[getAlbums] Failed while converting DB entry", e, stackTrace);
            return null;
          }
        })
        .whereNotNull()
        .toList();
  }

  @override
  Future<void> create(Account account, NcAlbum album) async {
    _log.info("[create] account: ${account.userId}, album: ${album.path}");
    await sqliteDb.use((db) async {
      await db.insertNcAlbum(
        account: sql.ByAccount.app(account),
        object: SqliteNcAlbumConverter.toSql(null, album),
      );
    });
  }

  @override
  Future<void> remove(Account account, NcAlbum album) async {
    _log.info("[remove] account: ${account.userId}, album: ${album.path}");
    await sqliteDb.use((db) async {
      await db.deleteNcAlbumByRelativePath(
        account: sql.ByAccount.app(account),
        relativePath: album.strippedPath,
      );
    });
  }

  @override
  Future<List<NcAlbumItem>> getItems(Account account, NcAlbum album) async {
    _log.info(
        "[getItems] account: ${account.userId}, album: ${album.strippedPath}");
    final dbItems = await sqliteDb.use((db) async {
      return await db.ncAlbumItemsByParentRelativePath(
        account: sql.ByAccount.app(account),
        parentRelativePath: album.strippedPath,
      );
    });
    return dbItems.map((i) => NcAlbumItem(i.fileId)).toList();
  }

  @override
  Future<void> updateAlbumsCache(Account account, List<NcAlbum> remote) async {
    await sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final existings = (await db.partialNcAlbumsByAccount(
        account: sql.ByAccount.sql(dbAccount),
        columns: [db.ncAlbums.rowId, db.ncAlbums.relativePath],
      ))
          .whereNotNull()
          .toList();
      await db.batch((batch) async {
        for (final r in remote) {
          final dbObj = SqliteNcAlbumConverter.toSql(dbAccount, r);
          final found = existings.indexWhere((e) => e[1] == r.strippedPath);
          if (found != -1) {
            // existing record, update it
            batch.update(
              db.ncAlbums,
              dbObj,
              where: (sql.$NcAlbumsTable t) =>
                  t.rowId.equals(existings[found][0]),
            );
          } else {
            // insert
            batch.insert(db.ncAlbums, dbObj);
          }
        }
        for (final e in existings
            .where((e) => !remote.any((r) => r.strippedPath == e[1]))) {
          batch.deleteWhere(
            db.ncAlbums,
            (sql.$NcAlbumsTable t) => t.rowId.equals(e[0]),
          );
        }
      });
    });
  }

  @override
  Future<void> updateItemsCache(
      Account account, NcAlbum album, List<NcAlbumItem> remote) async {
    await sqliteDb.use((db) async {
      final dbAlbum = await db.ncAlbumByRelativePath(
        account: sql.ByAccount.app(account),
        relativePath: album.strippedPath,
      );
      final existingItems = await db.ncAlbumItemsByParent(
        parent: dbAlbum!,
      );
      final idDiff = list_util.diff(
        existingItems.map((e) => e.fileId).sorted((a, b) => a.compareTo(b)),
        remote.map((e) => e.fileId).sorted((a, b) => a.compareTo(b)),
      );
      if (idDiff.onlyInA.isNotEmpty || idDiff.onlyInB.isNotEmpty) {
        await db.batch((batch) async {
          for (final id in idDiff.onlyInB) {
            // new
            batch.insert(
              db.ncAlbumItems,
              SqliteNcAlbumItemConverter.toSql(dbAlbum, id),
            );
          }
          // removed
          batch.deleteWhere(
            db.ncAlbumItems,
            (sql.$NcAlbumItemsTable t) =>
                t.parent.equals(dbAlbum.rowId) & t.fileId.isIn(idDiff.onlyInA),
          );
        });
      }
    });
  }

  final sql.SqliteDb sqliteDb;
}
