import 'package:event_bus/event_bus.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/list_util.dart' as list_util;
import 'package:nc_photos/use_case/list_favorite_offline.dart';

class CacheFavorite {
  CacheFavorite(this._c)
      : assert(require(_c)),
        assert(ListFavoriteOffline.require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.appDb);

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
    if (newFavorites.isEmpty && removedFavorites.isEmpty) {
      return;
    }
    await _c.appDb.use(
      (db) => db.transaction(AppDb.file2StoreName, idbModeReadWrite),
      (transaction) async {
        final fileStore = transaction.objectStore(AppDb.file2StoreName);
        await newFavorites.forEachAsync((f) async {
          _log.info("[call] New favorite: ${f.path}");
          try {
            await fileStore.put(AppDbFile2Entry.fromFile(account, f).toJson(),
                AppDbFile2Entry.toPrimaryKeyForFile(account, f));
          } catch (e, stackTrace) {
            _log.shout(
                "[call] Failed while writing new favorite to AppDb: ${logFilename(f.path)}",
                e,
                stackTrace);
          }
        }, k.simultaneousQuery);
        await removedFavorites.forEachAsync((f) async {
          _log.info("[call] Remove favorite: ${f.path}");
          try {
            await fileStore.put(AppDbFile2Entry.fromFile(account, f).toJson(),
                AppDbFile2Entry.toPrimaryKeyForFile(account, f));
          } catch (e, stackTrace) {
            _log.shout(
                "[call] Failed while writing removed favorite to AppDb: ${logFilename(f.path)}",
                e,
                stackTrace);
          }
        }, k.simultaneousQuery);
      },
    );

    KiwiContainer()
        .resolve<EventBus>()
        .fire(FavoriteResyncedEvent(account, newFavorites, removedFavorites));
  }

  final DiContainer _c;

  static final _log = Logger("use_case.cache_favorite.CacheFavorite");
}
