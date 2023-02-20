import 'package:drift/drift.dart' as sql;
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/files_query_builder.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;

class ScanDirOffline {
  ScanDirOffline(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  Future<List<FileDescriptor>> call(
    Account account,
    File root, {
    bool isOnlySupportedFormat = true,
  }) async {
    return await _c.sqliteDb.isolate({
      "account": account,
      "root": root,
      "isOnlySupportedFormat": isOnlySupportedFormat,
    }, (db, Map args) async {
      final Account account = args["account"];
      final File root = args["root"];
      final strippedPath = root.strippedPathWithEmpty;
      final bool isOnlySupportedFormat = args["isOnlySupportedFormat"];
      final dbFiles = await db.useInIsolate((db) async {
        final query = db.queryFiles().run((q) {
          q
            ..setQueryMode(
              sql.FilesQueryMode.expression,
              expressions: [
                db.accountFiles.relativePath,
                db.files.fileId,
                db.files.contentType,
                db.accountFiles.isArchived,
                db.accountFiles.isFavorite,
                db.accountFiles.bestDateTime,
              ],
            )
            ..setAppAccount(account);
          if (strippedPath.isNotEmpty) {
            q.byOrRelativePathPattern("$strippedPath/%");
          }
          return q.build();
        });
        if (isOnlySupportedFormat) {
          query.where(db.whereFileIsSupportedMime());
        }
        if (strippedPath.isEmpty) {
          query.where(db.accountFiles.relativePath
              .like("${remote_storage_util.remoteStorageDirRelativePath}/%")
              .not());
        }
        return await query
            .map((r) => <String, dynamic>{
                  "relativePath": r.read(db.accountFiles.relativePath)!,
                  "fileId": r.read(db.files.fileId)!,
                  "contentType": r.read(db.files.contentType)!,
                  "isArchived": r.read(db.accountFiles.isArchived),
                  "isFavorite": r.read(db.accountFiles.isFavorite),
                  "bestDateTime": r.read(db.accountFiles.bestDateTime)!.toUtc(),
                })
            .get();
      });
      return dbFiles
          .map((f) => FileDescriptor(
                fdPath:
                    "remote.php/dav/files/${account.userId.toString()}/${f["relativePath"]}",
                fdId: f["fileId"],
                fdMime: f["contentType"],
                fdIsArchived: f["isArchived"] ?? false,
                fdIsFavorite: f["isFavorite"] ?? false,
                fdDateTime: f["bestDateTime"],
              ))
          .toList();
    });
  }

  final DiContainer _c;
}

class ScanDirOfflineMini {
  ScanDirOfflineMini(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  Future<List<File>> call(
    Account account,
    Iterable<File> roots,
    int limit, {
    bool isOnlySupportedFormat = true,
  }) async {
    final dbFiles = await _c.sqliteDb.use((db) async {
      final query = db.queryFiles().run((q) {
        q
          ..setQueryMode(sql.FilesQueryMode.completeFile)
          ..setAppAccount(account);
        for (final r in roots) {
          final path = r.strippedPathWithEmpty;
          if (path.isEmpty) {
            break;
          }
          q.byOrRelativePathPattern("$path/%");
        }
        return q.build();
      });
      if (isOnlySupportedFormat) {
        query.where(db.whereFileIsSupportedMime());
      }
      query
        ..orderBy([sql.OrderingTerm.desc(db.accountFiles.bestDateTime)])
        ..limit(limit);
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
    return dbFiles
        .map((f) => SqliteFileConverter.fromSql(account.userId.toString(), f))
        .toList();
  }

  final DiContainer _c;
}
