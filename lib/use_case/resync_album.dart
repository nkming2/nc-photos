import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';

/// Resync files inside an album with the file db
class ResyncAlbum {
  const ResyncAlbum(this.appDb);

  Future<List<AlbumItem>> call(Account account, Album album) async {
    _log.info("[call] Resync album: ${album.name}");
    if (album.provider is! AlbumStaticProvider) {
      throw ArgumentError(
          "Resync only make sense for static albums: ${album.name}");
    }
    return await appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.file2StoreName);
      final index = store.index(AppDbFile2Entry.strippedPathIndexName);
      final newItems = <AlbumItem>[];
      for (final item in AlbumStaticProvider.of(album).items) {
        if (item is AlbumFileItem) {
          try {
            newItems.add(await _syncOne(account, item,
                fileStore: store, fileStoreStrippedPathIndex: index));
          } catch (e, stacktrace) {
            _log.shout(
                "[call] Failed syncing file in album: ${logFilename(item.file.path)}",
                e,
                stacktrace);
            newItems.add(item);
          }
        } else {
          newItems.add(item);
        }
      }
      return newItems;
    });
  }

  Future<AlbumFileItem> _syncOne(
    Account account,
    AlbumFileItem item, {
    required ObjectStore fileStore,
    required Index fileStoreStrippedPathIndex,
  }) async {
    Map? dbItem;
    if (item.file.fileId != null) {
      dbItem = await fileStore.getObject(
          AppDbFile2Entry.toPrimaryKeyForFile(account, item.file)) as Map?;
    } else {
      dbItem = await fileStoreStrippedPathIndex.get(
              AppDbFile2Entry.toStrippedPathIndexKeyForFile(account, item.file))
          as Map?;
    }
    if (dbItem == null) {
      _log.warning(
          "[_syncOne] File doesn't exist in DB, removed?: '${item.file.path}'");
      return item;
    }
    final dbEntry = AppDbFile2Entry.fromJson(dbItem.cast<String, dynamic>());
    return item.copyWith(
      file: dbEntry.file,
    );
  }

  final AppDb appDb;

  static final _log = Logger("use_case.resync_album.ResyncAlbum");
}
