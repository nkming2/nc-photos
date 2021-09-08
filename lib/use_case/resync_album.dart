import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;

/// Resync files inside an album with the file db
class ResyncAlbum {
  Future<Album> call(Account account, Album album) async {
    if (album.provider is! AlbumStaticProvider) {
      _log.warning(
          "[call] Resync only make sense for static albums: ${album.name}");
      return album;
    }
    return await AppDb.use((db) async {
      final transaction =
          db.transaction(AppDb.fileDbStoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.fileDbStoreName);
      final index = store.index(AppDbFileDbEntry.indexName);
      final newItems = <AlbumItem>[];
      for (final item in AlbumStaticProvider.of(album).items) {
        if (item is AlbumFileItem) {
          try {
            newItems.add(await _syncOne(account, item, store, index));
          } catch (e, stacktrace) {
            _log.shout(
                "[call] Failed syncing file in album" +
                    (shouldLogFileName ? ": '${item.file.path}'" : ""),
                e,
                stacktrace);
            newItems.add(item);
          }
        } else {
          newItems.add(item);
        }
      }
      return album.copyWith(provider: AlbumStaticProvider(items: newItems));
    });
  }

  Future<AlbumFileItem> _syncOne(Account account, AlbumFileItem item,
      ObjectStore objStore, Index index) async {
    Map? dbItem;
    if (item.file.fileId != null) {
      final List dbItems = await index
          .getAll(AppDbFileDbEntry.toNamespacedFileId(account, item.file));
      // find the one owned by us
      try {
        dbItem = dbItems.firstWhere((element) {
          final e = AppDbFileDbEntry.fromJson(element.cast<String, dynamic>());
          return file_util.getUserDirName(e.file) == account.username;
        });
      } on StateError catch (_) {
        // not found
      }
    } else {
      dbItem = await objStore
          .getObject(AppDbFileDbEntry.toPrimaryKey(account, item.file)) as Map;
    }
    if (dbItem == null) {
      _log.warning(
          "[_syncOne] File doesn't exist in DB, removed?: '${item.file.path}'");
      return item;
    }
    final dbEntry = AppDbFileDbEntry.fromJson(dbItem.cast<String, dynamic>());
    return AlbumFileItem(file: dbEntry.file);
  }

  static final _log = Logger("use_case.resync_album.ResyncAlbum");
}
