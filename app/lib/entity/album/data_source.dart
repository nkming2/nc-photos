import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' as sql;
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/future_util.dart' as future_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:nc_photos/use_case/put_file_binary.dart';
import 'package:np_codegen/np_codegen.dart';

part 'data_source.g.dart';

@npLog
class AlbumRemoteDataSource implements AlbumDataSource {
  @override
  get(Account account, File albumFile) async {
    _log.info("[get] ${albumFile.path}");
    const fileRepo = FileRepo(FileWebdavDataSource());
    final data = await GetFileBinary(fileRepo)(account, albumFile);
    try {
      return Album.fromJson(
        jsonDecode(utf8.decode(data)),
        upgraderFactory: DefaultAlbumUpgraderFactory(
          account: account,
          albumFile: albumFile,
          logFilePath: albumFile.path,
        ),
      )!
          .copyWith(
        lastUpdated: OrNull(null),
        albumFile: OrNull(albumFile),
      );
    } catch (e, stacktrace) {
      dynamic d = data;
      try {
        d = utf8.decode(data);
      } catch (_) {}
      _log.severe("[get] Invalid json data: $d", e, stacktrace);
      throw const FormatException("Invalid album format");
    }
  }

  @override
  getAll(Account account, List<File> albumFiles) async* {
    _log.info(
        "[getAll] ${albumFiles.map((f) => f.filename).toReadableString()}");
    final results = await future_util.waitOr(
      albumFiles.map((f) => get(account, f)),
      (error, stackTrace) => ExceptionEvent(error, stackTrace),
    );
    for (final r in results) {
      yield r;
    }
  }

  @override
  create(Account account, Album album) async {
    _log.info("[create]");
    final fileName = _makeAlbumFileName();
    final filePath =
        "${remote_storage_util.getRemoteAlbumsDir(account)}/$fileName";
    final c = KiwiContainer().resolve<DiContainer>();
    await PutFileBinary(c.fileRepo)(account, filePath,
        const Utf8Encoder().convert(jsonEncode(album.toRemoteJson())),
        shouldCreateMissingDir: true);
    // query album file
    final newFile = await LsSingleFile(c)(account, filePath);
    return album.copyWith(albumFile: OrNull(newFile));
  }

  @override
  update(Account account, Album album) async {
    _log.info("[update] ${album.albumFile!.path}");
    const fileRepo = FileRepo(FileWebdavDataSource());
    await PutFileBinary(fileRepo)(account, album.albumFile!.path,
        const Utf8Encoder().convert(jsonEncode(album.toRemoteJson())));
  }

  String _makeAlbumFileName() {
    // just make up something
    final timestamp = clock.now().millisecondsSinceEpoch;
    final random = Random().nextInt(0xFFFFFF);
    return "${timestamp.toRadixString(16)}-${random.toRadixString(16).padLeft(6, '0')}.nc_album.json";
  }
}

@npLog
class AlbumSqliteDbDataSource implements AlbumDataSource {
  AlbumSqliteDbDataSource(this._c);

  @override
  get(Account account, File albumFile) async {
    final results = await getAll(account, [albumFile]).toList();
    if (results.first is! Album) {
      throw results.first;
    } else {
      return results.first;
    }
  }

  @override
  getAll(Account account, List<File> albumFiles) async* {
    _log.info(
        "[getAll] ${albumFiles.map((f) => f.filename).toReadableString()}");
    late final List<sql.CompleteFile> dbFiles;
    late final List<sql.AlbumWithShare> albumWithShares;
    await _c.sqliteDb.use((db) async {
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
        _log.severe("[getAll] File missing for album (rowId: ${s.album.rowId}");
      } else {
        if (!fileIdMap.containsKey(f.file.fileId)) {
          fileIdMap[f.file.fileId] = {
            "file": f,
            "album": s.album,
          };
        }
        if (s.share != null) {
          (fileIdMap[f.file.fileId]!["shares"] ??= <sql.AlbumShare>[])
              .add(s.share!);
        }
      }
    }

    // sort as the input list
    for (final item in albumFiles.map((f) => fileIdMap[f.fileId])) {
      if (item == null) {
        // cache not found
        yield CacheNotFoundException();
      } else {
        try {
          final f = SqliteFileConverter.fromSql(
              account.userId.toString(), item["file"]);
          yield SqliteAlbumConverter.fromSql(
              item["album"], f, item["shares"] ?? []);
        } catch (e, stackTrace) {
          _log.severe(
              "[getAll] Failed while converting DB entry", e, stackTrace);
          yield ExceptionEvent(e, stackTrace);
        }
      }
    }
  }

  @override
  create(Account account, Album album) async {
    _log.info("[create]");
    throw UnimplementedError();
  }

  @override
  update(Account account, Album album) async {
    _log.info("[update] ${album.albumFile!.path}");
    await _c.sqliteDb.use((db) async {
      final rowIds =
          await db.accountFileRowIdsOf(album.albumFile!, appAccount: account);
      final insert = SqliteAlbumConverter.toSql(
          album, rowIds.fileRowId, album.albumFile!.etag!);
      var rowId = await _updateCache(db, rowIds.fileRowId, insert.album);
      if (rowId == null) {
        // new album, need insert
        _log.info("[update] Insert new album");
        final insertedAlbum =
            await db.into(db.albums).insertReturning(insert.album);
        rowId = insertedAlbum.rowId;
      } else {
        await (db.delete(db.albumShares)..where((t) => t.album.equals(rowId)))
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

  final DiContainer _c;
}

@npLog
class AlbumCachedDataSource implements AlbumDataSource {
  AlbumCachedDataSource(DiContainer c)
      : _sqliteDbSrc = AlbumSqliteDbDataSource(c);

  @override
  get(Account account, File albumFile) async {
    final result = await getAll(account, [albumFile]).first;
    return result as Album;
  }

  @override
  getAll(Account account, List<File> albumFiles) async* {
    var i = 0;
    await for (final cache in _sqliteDbSrc.getAll(account, albumFiles)) {
      final albumFile = albumFiles[i++];
      if (_validateCache(cache, albumFile)) {
        yield cache;
      } else {
        // no cache
        final remote = await _remoteSrc.get(account, albumFile);
        await _cacheResult(account, remote);
        yield remote;
      }
    }
  }

  @override
  update(Account account, Album album) async {
    await _remoteSrc.update(account, album);
    await _sqliteDbSrc.update(account, album);
  }

  @override
  create(Account account, Album album) => _remoteSrc.create(account, album);

  Future<void> _cacheResult(Account account, Album result) {
    return _sqliteDbSrc.update(account, result);
  }

  bool _validateCache(dynamic cache, File albumFile) {
    if (cache is Album) {
      if (cache.albumFile!.etag?.isNotEmpty == true &&
          cache.albumFile!.etag == albumFile.etag) {
        // cache is good
        _log.fine("[_validateCache] etag matched for ${albumFile.path}");
        return true;
      } else {
        _log.info(
            "[_validateCache] Remote content updated for ${albumFile.path}");
        return false;
      }
    } else if (cache is CacheNotFoundException) {
      // normal when there's no cache
      return false;
    } else if (cache is ExceptionEvent) {
      _log.shout(
          "[_validateCache] Cache failure", cache.error, cache.stackTrace);
      return false;
    } else {
      _log.shout("[_validateCache] Unknown type: ${cache.runtimeType}");
      return false;
    }
  }

  final _remoteSrc = AlbumRemoteDataSource();
  final AlbumSqliteDbDataSource _sqliteDbSrc;
}
