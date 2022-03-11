import 'package:collection/collection.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:path/path.dart' as path_lib;

/// Compatibility helper for v37
class CompatV37 {
  static Future<void> setAppDbMigrationFlag(AppDb appDb) async {
    _log.info("[setAppDbMigrationFlag] Set db flag");
    try {
      await appDb.use((db) async {
        final transaction =
            db.transaction(AppDb.metaStoreName, idbModeReadWrite);
        final metaStore = transaction.objectStore(AppDb.metaStoreName);
        await metaStore
            .put(const AppDbMetaEntryCompatV37(false).toEntry().toJson());
        await transaction.completed;
      });
    } catch (e, stackTrace) {
      _log.shout(
          "[setAppDbMigrationFlag] Failed while setting db flag, drop db instead",
          e,
          stackTrace);
      await appDb.delete();
    }
  }

  static Future<bool> isAppDbNeedMigration(AppDb appDb) async {
    final dbItem = await appDb.use((db) async {
      final transaction = db.transaction(AppDb.metaStoreName, idbModeReadOnly);
      final metaStore = transaction.objectStore(AppDb.metaStoreName);
      return await metaStore.getObject(AppDbMetaEntryCompatV37.key) as Map?;
    });
    if (dbItem == null) {
      return false;
    }
    try {
      final dbEntry = AppDbMetaEntry.fromJson(dbItem.cast<String, dynamic>());
      final compatV37 = AppDbMetaEntryCompatV37.fromJson(dbEntry.obj);
      return !compatV37.isMigrated;
    } catch (e, stackTrace) {
      _log.shout("[isAppDbNeedMigration] Failed", e, stackTrace);
      return true;
    }
  }

  static Future<void> migrateAppDb(AppDb appDb) async {
    _log.info("[migrateAppDb] Migrate AppDb");
    try {
      await appDb.use((db) async {
        final transaction = db.transaction(
            [AppDb.file2StoreName, AppDb.dirStoreName, AppDb.metaStoreName],
            idbModeReadWrite);
        final noMediaFiles = <_NoMediaFile>[];
        try {
          final fileStore = transaction.objectStore(AppDb.file2StoreName);
          final dirStore = transaction.objectStore(AppDb.dirStoreName);
          // scan the db to see which dirs contain a no media marker
          await for (final c in fileStore.openCursor()) {
            final item = c.value as Map;
            final strippedPath = item["strippedPath"] as String;
            if (file_util.isNoMediaMarkerPath(strippedPath)) {
              noMediaFiles.add(_NoMediaFile(
                item["server"],
                item["userId"],
                path_lib
                    .dirname(item["strippedPath"])
                    .run((p) => p == "." ? "" : p),
                item["file"]["fileId"],
              ));
            }
            c.next();
          }
          // sort to make sure parent dirs are always in front of sub dirs
          noMediaFiles
              .sort((a, b) => a.strippedDirPath.compareTo(b.strippedDirPath));
          _log.info(
              "[migrateAppDb] nomedia dirs: ${noMediaFiles.toReadableString()}");

          if (noMediaFiles.isNotEmpty) {
            await _migrateAppDbFileStore(appDb, noMediaFiles,
                fileStore: fileStore);
            await _migrateAppDbDirStore(appDb, noMediaFiles,
                dirStore: dirStore);
          }

          final metaStore = transaction.objectStore(AppDb.metaStoreName);
          await metaStore
              .put(const AppDbMetaEntryCompatV37(true).toEntry().toJson());
        } catch (_) {
          transaction.abort();
          rethrow;
        }
      });
    } catch (e, stackTrace) {
      _log.shout("[migrateAppDb] Failed while migrating, drop db instead", e,
          stackTrace);
      await appDb.delete();
      rethrow;
    }
  }

  /// Remove files under no media dirs
  static Future<void> _migrateAppDbFileStore(
    AppDb appDb,
    List<_NoMediaFile> noMediaFiles, {
    required ObjectStore fileStore,
  }) async {
    await for (final c in fileStore.openCursor()) {
      final item = c.value as Map;
      final under = noMediaFiles.firstWhereOrNull((e) {
        if (e.server != item["server"] || e.userId != item["userId"]) {
          return false;
        }
        final prefix = e.strippedDirPath.isEmpty ? "" : "${e.strippedDirPath}/";
        final itemDir = path_lib
            .dirname(item["strippedPath"])
            .run((p) => p == "." ? "" : p);
        // check isNotEmpty to prevent user root being removed when the
        // marker is placed in root
        return item["strippedPath"].isNotEmpty &&
            item["strippedPath"].startsWith(prefix) &&
            // keep no media marker in top-most dir
            !(itemDir == e.strippedDirPath &&
                file_util.isNoMediaMarkerPath(item["strippedPath"]));
      });
      if (under != null) {
        _log.fine("[_migrateAppDbFileStore] Remove db entry: ${c.primaryKey}");
        await c.delete();
      }
      c.next();
    }
  }

  /// Remove dirs under no media dirs
  static Future<void> _migrateAppDbDirStore(
    AppDb appDb,
    List<_NoMediaFile> noMediaFiles, {
    required ObjectStore dirStore,
  }) async {
    await for (final c in dirStore.openCursor()) {
      final item = c.value as Map;
      final under = noMediaFiles.firstWhereOrNull((e) {
        if (e.server != item["server"] || e.userId != item["userId"]) {
          return false;
        }
        final prefix = e.strippedDirPath.isEmpty ? "" : "${e.strippedDirPath}/";
        return item["strippedPath"].startsWith(prefix) ||
            e.strippedDirPath == item["strippedPath"];
      });
      if (under != null) {
        if (under.strippedDirPath == item["strippedPath"]) {
          // this dir contains the no media marker
          // remove all children, keep only the marker
          final newChildren = (item["children"] as List)
              .where((childId) => childId == under.fileId)
              .toList();
          if (newChildren.isEmpty) {
            // ???
            _log.severe(
                "[_migrateAppDbDirStore] Marker not found in dir: ${item["strippedPath"]}");
            // drop this dir
            await c.delete();
          }
          _log.fine(
              "[_migrateAppDbDirStore] Migrate db entry: ${c.primaryKey}");
          await c.update(Map.of(item).apply((obj) {
            obj["children"] = newChildren;
          }));
        } else {
          // this dir is a sub dir
          // drop this dir
          _log.fine("[_migrateAppDbDirStore] Remove db entry: ${c.primaryKey}");
          await c.delete();
        }
      }
      c.next();
    }
  }

  static final _log = Logger("use_case.compat.v37.CompatV37");
}

class _NoMediaFile {
  const _NoMediaFile(
      this.server, this.userId, this.strippedDirPath, this.fileId);

  @override
  toString() => "$runtimeType {"
      "server: $server, "
      "userId: $userId, "
      "strippedDirPath: $strippedDirPath, "
      "fileId: $fileId, "
      "}";

  final String server;
  // no need to use CiString as all strings are stored with the same casing in
  // db
  final String userId;
  final String strippedDirPath;
  final int fileId;
}
