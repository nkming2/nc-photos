import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/files_query_builder.dart' as sql;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_collection/np_collection.dart';

part 'cache_favorite.g.dart';

@npLog
class CacheFavorite {
  CacheFavorite(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// Cache favorites using results from remote
  ///
  /// Return number of files updated
  Future<int> call(Account account, Iterable<int> remoteFileIds) async {
    _log.info("[call] Cache favorites");
    final remote = remoteFileIds.sorted(Comparable.compare);
    final updateCount = await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      final cache = await _getCacheFavorites(db, dbAccount);
      final cacheMap =
          Map.fromEntries(cache.map((e) => MapEntry(e.fileId, e.rowId)));
      final diff = getDiff(cacheMap.keys.sorted(Comparable.compare), remote);
      final newFileIds = diff.onlyInB;
      _log.info("[call] New favorites: ${newFileIds.toReadableString()}");
      final removedFildIds = diff.onlyInA;
      _log.info(
          "[call] Removed favorites: ${removedFildIds.toReadableString()}");

      var updateCount = 0;
      if (newFileIds.isNotEmpty) {
        final rowIds = await db.accountFileRowIdsByFileIds(
            sql.ByAccount.sql(dbAccount), newFileIds);
        final counts =
            await rowIds.map((id) => id.accountFileRowId).withPartition(
          (sublist) async {
            return [
              await (db.update(db.accountFiles)
                    ..where((t) => t.rowId.isIn(sublist)))
                  .write(const sql.AccountFilesCompanion(
                      isFavorite: sql.Value(true))),
            ];
          },
          sql.maxByFileIdsSize,
        );
        final count = counts.sum;
        _log.info("[call] Updated $count row (new)");
        updateCount += count;
      }
      if (removedFildIds.isNotEmpty) {
        final counts =
            await removedFildIds.map((id) => cacheMap[id]!).withPartition(
          (sublist) async {
            return [
              await (db.update(db.accountFiles)
                    ..where((t) =>
                        t.account.equals(dbAccount.rowId) &
                        t.file.isIn(sublist)))
                  .write(const sql.AccountFilesCompanion(
                      isFavorite: sql.Value(false)))
            ];
          },
          sql.maxByFileIdsSize,
        );
        final count = counts.sum;
        _log.info("[call] Updated $count row (remove)");
        updateCount += count;
      }
      return updateCount;
    });

    if (updateCount > 0) {
      KiwiContainer().resolve<EventBus>().fire(FavoriteResyncedEvent(account));
    }
    return updateCount;
  }

  Future<List<_FileRowIdWithFileId>> _getCacheFavorites(
      sql.SqliteDb db, sql.Account dbAccount) async {
    final query = db.queryFiles().run((q) {
      q
        ..setQueryMode(sql.FilesQueryMode.expression,
            expressions: [db.files.rowId, db.files.fileId])
        ..setSqlAccount(dbAccount)
        ..byFavorite(true);
      return q.build();
    });
    return await query
        .map((r) => _FileRowIdWithFileId(
            r.read(db.files.rowId)!, r.read(db.files.fileId)!))
        .get();
  }

  final DiContainer _c;
}

class _FileRowIdWithFileId {
  const _FileRowIdWithFileId(this.rowId, this.fileId);

  final int rowId;
  final int fileId;
}
