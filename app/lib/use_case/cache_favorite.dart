import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/list_util.dart' as list_util;
import 'package:nc_photos/object_extension.dart';

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
      final diff =
          list_util.diff(cacheMap.keys.sorted(Comparable.compare), remote);
      final newFileIds = diff.item1;
      _log.info("[call] New favorites: ${newFileIds.toReadableString()}");
      final removedFildIds = diff.item2;
      _log.info(
          "[call] Removed favorites: ${removedFildIds.toReadableString()}");

      var updateCount = 0;
      if (newFileIds.isNotEmpty) {
        final rowIds = await db.accountFileRowIdsByFileIds(newFileIds,
            sqlAccount: dbAccount);
        final count = await (db.update(db.accountFiles)
              ..where(
                  (t) => t.rowId.isIn(rowIds.map((id) => id.accountFileRowId))))
            .write(
                const sql.AccountFilesCompanion(isFavorite: sql.Value(true)));
        _log.info("[call] Updated $count row (new)");
        updateCount += count;
      }
      if (removedFildIds.isNotEmpty) {
        final count = await (db.update(db.accountFiles)
              ..where((t) =>
                  t.account.equals(dbAccount.rowId) &
                  t.file.isIn(removedFildIds.map((id) => cacheMap[id]))))
            .write(
                const sql.AccountFilesCompanion(isFavorite: sql.Value(false)));
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

  static final _log = Logger("use_case.cache_favorite.CacheFavorite");
}

class _FileRowIdWithFileId {
  const _FileRowIdWithFileId(this.rowId, this.fileId);

  final int rowId;
  final int fileId;
}
