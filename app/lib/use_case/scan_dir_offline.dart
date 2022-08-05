import 'package:drift/drift.dart' as sql;
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite_table_converter.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/object_extension.dart';

class ScanDirOffline {
  ScanDirOffline(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  Future<List<File>> call(
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
      final bool isOnlySupportedFormat = args["isOnlySupportedFormat"];
      final dbFiles = await db.useInIsolate((db) async {
        final query = db.queryFiles().run((q) {
          q
            ..setQueryMode(sql.FilesQueryMode.completeFile)
            ..setAppAccount(account);
          root.strippedPathWithEmpty.run((p) {
            if (p.isNotEmpty) {
              q.byOrRelativePathPattern("$p/%");
            }
          });
          if (isOnlySupportedFormat) {
            q
              ..byMimePattern("image/%")
              ..byMimePattern("video/%");
          }
          return q.build();
        });
        return await query
            .map((r) => sql.CompleteFile(
                  r.readTable(db.files),
                  r.readTable(db.accountFiles),
                  r.readTableOrNull(db.images),
                  r.readTableOrNull(db.trashes),
                ))
            .get();
      });
      return dbFiles
          .map((f) => SqliteFileConverter.fromSql(account.userId.toString(), f))
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
        if (isOnlySupportedFormat) {
          q
            ..byMimePattern("image/%")
            ..byMimePattern("video/%");
        }
        return q.build();
      });
      query
        ..orderBy([sql.OrderingTerm.desc(db.accountFiles.bestDateTime)])
        ..limit(limit);
      return await query
          .map((r) => sql.CompleteFile(
                r.readTable(db.files),
                r.readTable(db.accountFiles),
                r.readTableOrNull(db.images),
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
