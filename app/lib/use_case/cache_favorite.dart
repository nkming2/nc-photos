import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/list_util.dart' as list_util;
import 'package:nc_photos/use_case/list_favorite_offline.dart';

class CacheFavorite {
  CacheFavorite(this._c)
      : assert(require(_c)),
        assert(ListFavoriteOffline.require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// Cache favorites
  Future<void> call(
    Account account,
    List<File> remote, {
    List<File>? cache,
  }) async {
    cache ??= await ListFavoriteOffline(_c)(account);
    final remoteSorted =
        remote.sorted((a, b) => a.fileId!.compareTo(b.fileId!));
    final cacheSorted = cache.sorted((a, b) => a.fileId!.compareTo(b.fileId!));
    final result = list_util.diffWith<File>(
        cacheSorted, remoteSorted, (a, b) => a.fileId!.compareTo(b.fileId!));
    final newFavorites = result.item1;
    final removedFavorites =
        result.item2.map((f) => f.copyWith(isFavorite: false)).toList();
    final newFileIds = newFavorites.map((f) => f.fileId!).toList();
    final removedFileIds = removedFavorites.map((f) => f.fileId!).toList();
    if (newFileIds.isEmpty && removedFileIds.isEmpty) {
      return;
    }
    await _c.sqliteDb.use((db) async {
      final rowIds = await db.accountFileRowIdsByFileIds(
        newFileIds + removedFileIds,
        appAccount: account,
      );
      final rowIdsMap =
          Map.fromEntries(rowIds.map((e) => MapEntry(e.fileId, e)));
      await db.batch((batch) {
        for (final id in newFileIds) {
          try {
            batch.update(
              db.accountFiles,
              const sql.AccountFilesCompanion(isFavorite: sql.Value(true)),
              where: (sql.$AccountFilesTable t) =>
                  t.rowId.equals(rowIdsMap[id]!.accountFileRowId),
            );
          } catch (e, stackTrace) {
            _log.shout("[call] File not found in DB: $id", e, stackTrace);
          }
        }
        for (final id in removedFileIds) {
          try {
            batch.update(
              db.accountFiles,
              const sql.AccountFilesCompanion(isFavorite: sql.Value(null)),
              where: (sql.$AccountFilesTable t) =>
                  t.rowId.equals(rowIdsMap[id]!.accountFileRowId),
            );
          } catch (e, stackTrace) {
            _log.shout("[call] File not found in DB: $id", e, stackTrace);
          }
        }
      });
    });

    KiwiContainer()
        .resolve<EventBus>()
        .fire(FavoriteResyncedEvent(account, newFavorites, removedFavorites));
  }

  final DiContainer _c;

  static final _log = Logger("use_case.cache_favorite.CacheFavorite");
}
