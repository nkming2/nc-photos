import 'package:drift/drift.dart' as sql;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/iterable_extension.dart';
import 'package:tuple/tuple.dart';

class CompatV55 {
  static Future<void> migrateDb(
    sql.SqliteDb db, {
    void Function(int current, int count)? onProgress,
  }) {
    return db.use((db) async {
      final countExp = db.accountFiles.rowId.count();
      final countQ = db.selectOnly(db.accountFiles)..addColumns([countExp]);
      final count = await countQ.map((r) => r.read<int>(countExp)).getSingle();
      onProgress?.call(0, count);

      final needUpdates = <Tuple2<int, DateTime>>[];
      for (var i = 0; i < count; i += 1000) {
        final q = db.select(db.files).join([
          sql.innerJoin(
              db.accountFiles, db.accountFiles.file.equalsExp(db.files.rowId)),
          sql.innerJoin(db.images,
              db.images.accountFile.equalsExp(db.accountFiles.rowId)),
        ]);
        q
          ..orderBy([
            sql.OrderingTerm(
              expression: db.accountFiles.rowId,
              mode: sql.OrderingMode.asc,
            ),
          ])
          ..limit(1000, offset: i);
        final dbFiles = await q
            .map((r) => sql.CompleteFile(
                  r.readTable(db.files),
                  r.readTable(db.accountFiles),
                  r.readTable(db.images),
                  null,
                  null,
                ))
            .get();
        for (final f in dbFiles) {
          final bestDateTime = file_util.getBestDateTime(
            overrideDateTime: f.accountFile.overrideDateTime,
            dateTimeOriginal: f.image?.dateTimeOriginal,
            lastModified: f.file.lastModified,
          );
          if (f.accountFile.bestDateTime != bestDateTime) {
            // need update
            needUpdates.add(Tuple2(f.accountFile.rowId, bestDateTime));
          }
        }
        onProgress?.call(i, count);
      }

      _log.info("[migrateDb] ${needUpdates.length} rows require updating");
      if (kDebugMode) {
        _log.fine(
            "[migrateDb] ${needUpdates.map((e) => e.item1).toReadableString()}");
      }
      await db.batch((batch) {
        for (final pair in needUpdates) {
          batch.update(
            db.accountFiles,
            sql.AccountFilesCompanion(
              bestDateTime: sql.Value(pair.item2),
            ),
            where: (sql.$AccountFilesTable table) =>
                table.rowId.equals(pair.item1),
          );
        }
      });
    });
  }

  static final _log = Logger("use_case.compat.v55.CompatV55");
}
