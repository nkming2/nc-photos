import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/object_extension.dart';

class DbCompatV5 {
  static Future<bool> isNeedMigration(AppDb appDb) async {
    final dbItem = await appDb.use(
      (db) => db.transaction(AppDb.metaStoreName, idbModeReadOnly),
      (transaction) async {
        final metaStore = transaction.objectStore(AppDb.metaStoreName);
        return await metaStore.getObject(AppDbMetaEntryDbCompatV5.key) as Map?;
      },
    );
    if (dbItem == null) {
      return false;
    }
    try {
      final dbEntry = AppDbMetaEntry.fromJson(dbItem.cast<String, dynamic>());
      final compatV35 = AppDbMetaEntryDbCompatV5.fromJson(dbEntry.obj);
      return !compatV35.isMigrated;
    } catch (e, stackTrace) {
      _log.shout("[isNeedMigration] Failed", e, stackTrace);
      return true;
    }
  }

  static Future<void> migrate(AppDb appDb) async {
    _log.info("[migrate] Migrate AppDb");
    try {
      await appDb.use(
        (db) => db.transaction(
            [AppDb.file2StoreName, AppDb.metaStoreName], idbModeReadWrite),
        (transaction) async {
          try {
            final fileStore = transaction.objectStore(AppDb.file2StoreName);
            await for (final c in fileStore.openCursor()) {
              final item = c.value as Map;
              // migrate file entry: add bestDateTime
              final fileEntry = item.cast<String, dynamic>().run((json) {
                final f = File.fromJson(json["file"].cast<String, dynamic>());
                return AppDbFile2Entry(
                  json["server"],
                  (json["userId"] as String).toCi(),
                  json["strippedPath"],
                  f.bestDateTime.millisecondsSinceEpoch,
                  File.fromJson(json["file"].cast<String, dynamic>()),
                );
              });
              await c.update(fileEntry.toJson());

              c.next();
            }
            final metaStore = transaction.objectStore(AppDb.metaStoreName);
            await metaStore
                .put(const AppDbMetaEntryDbCompatV5(true).toEntry().toJson());
          } catch (_) {
            transaction.abort();
            rethrow;
          }
        },
      );
    } catch (e, stackTrace) {
      _log.shout(
          "[migrate] Failed while migrating, drop db instead", e, stackTrace);
      await appDb.delete();
      rethrow;
    }
  }

  static final _log = Logger("use_case.db_compat.v5.DbCompatV5");
}
