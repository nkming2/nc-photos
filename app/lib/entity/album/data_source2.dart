import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/repo2.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart' as sql;
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:nc_photos/use_case/put_file_binary.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/or_null.dart';
import 'package:np_common/type.dart';

part 'data_source2.g.dart';

@npLog
class AlbumRemoteDataSource2 implements AlbumDataSource2 {
  const AlbumRemoteDataSource2();

  @override
  Future<List<Album>> getAlbums(
    Account account,
    List<File> albumFiles, {
    ErrorWithValueHandler<File>? onError,
  }) async {
    final results = await Future.wait(albumFiles.map((f) async {
      try {
        return await _getSingle(account, f);
      } catch (e, stackTrace) {
        onError?.call(f, e, stackTrace);
        return null;
      }
    }));
    return results.whereNotNull().toList();
  }

  @override
  Future<Album> create(Account account, Album album) async {
    _log.info("[create] ${album.name}");
    final fileName = _makeAlbumFileName();
    final filePath =
        "${remote_storage_util.getRemoteAlbumsDir(account)}/$fileName";
    final c = KiwiContainer().resolve<DiContainer>();
    await PutFileBinary(c.fileRepo)(
      account,
      filePath,
      const Utf8Encoder().convert(jsonEncode(album.toRemoteJson())),
      shouldCreateMissingDir: true,
    );
    // query album file
    final newFile = await LsSingleFile(c)(account, filePath);
    return album.copyWith(albumFile: OrNull(newFile));
  }

  @override
  Future<void> update(Account account, Album album) async {
    _log.info("[update] ${album.albumFile!.path}");
    const fileRepo = FileRepo(FileWebdavDataSource());
    await PutFileBinary(fileRepo)(
      account,
      album.albumFile!.path,
      const Utf8Encoder().convert(jsonEncode(album.toRemoteJson())),
    );
  }

  Future<Album> _getSingle(Account account, File albumFile) async {
    _log.info("[_getSingle] Getting ${albumFile.path}");
    const fileRepo = FileRepo(FileWebdavDataSource());
    final data = await GetFileBinary(fileRepo)(account, albumFile);
    try {
      final album = Album.fromJson(
        jsonDecode(utf8.decode(data)),
        upgraderFactory: DefaultAlbumUpgraderFactory(
          account: account,
          albumFile: albumFile,
          logFilePath: albumFile.path,
        ),
      );
      return album!.copyWith(
        lastUpdated: const OrNull(null),
        albumFile: OrNull(albumFile),
      );
    } catch (e, stacktrace) {
      dynamic d = data;
      try {
        d = utf8.decode(data);
      } catch (_) {}
      _log.severe("[_getSingle] Invalid json data: $d", e, stacktrace);
      throw const FormatException("Invalid album format");
    }
  }

  String _makeAlbumFileName() {
    // just make up something
    final timestamp = clock.now().millisecondsSinceEpoch;
    final random = Random().nextInt(0xFFFFFF);
    return "${timestamp.toRadixString(16)}-${random.toRadixString(16).padLeft(6, '0')}.nc_album.json";
  }
}

@npLog
class AlbumSqliteDbDataSource2 implements AlbumDataSource2 {
  const AlbumSqliteDbDataSource2(this.sqliteDb);

  @override
  Future<List<Album>> getAlbums(
    Account account,
    List<File> albumFiles, {
    ErrorWithValueHandler<File>? onError,
  }) async {
    late final List<sql.CompleteFile> dbFiles;
    late final List<sql.AlbumWithShare> albumWithShares;
    await sqliteDb.use((db) async {
      dbFiles = await db.completeFilesByFileIds(
        albumFiles.map((f) => f.fileId!),
        appAccount: account,
      );
      final query = db.select(db.albums).join([
        sql.leftOuterJoin(
            db.albumShares, db.albumShares.album.equalsExp(db.albums.rowId)),
      ])
        ..where(db.albums.file.isIn(dbFiles.map((f) => f.file.rowId)));
      albumWithShares = await query
          .map((r) => sql.AlbumWithShare(
              r.readTable(db.albums), r.readTableOrNull(db.albumShares)))
          .get();
    });

    // group entries together
    final fileRowIdMap = <int, sql.CompleteFile>{};
    for (var f in dbFiles) {
      fileRowIdMap[f.file.rowId] = f;
    }
    final fileIdMap = <int, Map>{};
    for (final s in albumWithShares) {
      final f = fileRowIdMap[s.album.file];
      if (f == null) {
        _log.severe(
            "[getAlbums] File missing for album (rowId: ${s.album.rowId}");
      } else {
        fileIdMap[f.file.fileId] ??= {
          "file": f,
          "album": s.album,
        };
        if (s.share != null) {
          (fileIdMap[f.file.fileId]!["shares"] ??= <sql.AlbumShare>[])
              .add(s.share!);
        }
      }
    }

    // sort as the input list
    return albumFiles
        .map((f) {
          final item = fileIdMap[f.fileId];
          if (item == null) {
            // cache not found
            onError?.call(
                f, const CacheNotFoundException(), StackTrace.current);
            return null;
          } else {
            try {
              final queriedFile = sql.SqliteFileConverter.fromSql(
                  account.userId.toString(), item["file"]);
              var dbAlbum = item["album"] as sql.Album;
              if (dbAlbum.version < 9) {
                dbAlbum = AlbumUpgraderV8(logFilePath: queriedFile.path)
                    .doDb(dbAlbum)!;
              }
              return sql.SqliteAlbumConverter.fromSql(
                  dbAlbum, queriedFile, item["shares"] ?? []);
            } catch (e, stackTrace) {
              _log.severe("[getAlbums] Failed while converting DB entry", e,
                  stackTrace);
              onError?.call(f, e, stackTrace);
              return null;
            }
          }
        })
        .whereNotNull()
        .toList();
  }

  @override
  Future<Album> create(Account account, Album album) async {
    _log.info("[create] ${album.name}");
    throw UnimplementedError();
  }

  @override
  Future<void> update(Account account, Album album) async {
    _log.info("[update] ${album.albumFile!.path}");
    await sqliteDb.use((db) async {
      final rowIds =
          await db.accountFileRowIdsOf(album.albumFile!, appAccount: account);
      final insert = sql.SqliteAlbumConverter.toSql(
          album, rowIds.fileRowId, album.albumFile!.etag!);
      var rowId = await _updateCache(db, rowIds.fileRowId, insert.album);
      if (rowId == null) {
        // new album, need insert
        _log.info("[update] Insert new album");
        final insertedAlbum =
            await db.into(db.albums).insertReturning(insert.album);
        rowId = insertedAlbum.rowId;
      } else {
        await (db.delete(db.albumShares)..where((t) => t.album.equals(rowId!)))
            .go();
      }
      if (insert.albumShares.isNotEmpty) {
        await db.batch((batch) {
          batch.insertAll(
            db.albumShares,
            insert.albumShares.map((s) => s.copyWith(album: sql.Value(rowId!))),
          );
        });
      }
    });
  }

  Future<int?> _updateCache(
      sql.SqliteDb db, int dbFileRowId, sql.AlbumsCompanion dbAlbum) async {
    final rowIdQuery = db.selectOnly(db.albums)
      ..addColumns([db.albums.rowId])
      ..where(db.albums.file.equals(dbFileRowId))
      ..limit(1);
    final rowId =
        await rowIdQuery.map((r) => r.read(db.albums.rowId)!).getSingleOrNull();
    if (rowId == null) {
      // new album
      return null;
    }

    await (db.update(db.albums)..where((t) => t.rowId.equals(rowId)))
        .write(dbAlbum);
    return rowId;
  }

  final sql.SqliteDb sqliteDb;
}
