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
    final items = AlbumStaticProvider.of(album).items;
    final fileIds =
        items.whereType<AlbumFileItem>().map((i) => i.file.fileId!).toList();
    final dbItems = Map.fromEntries(await appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.file2StoreName);
      return await Future.wait(fileIds.map(
        (id) async => MapEntry(
          id,
          await store.getObject(AppDbFile2Entry.toPrimaryKey(account, id))
              as Map?,
        ),
      ));
    }));
    return items.map((i) {
      if (i is AlbumFileItem) {
        try {
          final dbItem = dbItems[i.file.fileId]!;
          final dbEntry =
              AppDbFile2Entry.fromJson(dbItem.cast<String, dynamic>());
          return i.copyWith(
            file: dbEntry.file,
          );
        } catch (e, stackTrace) {
          _log.shout(
              "[call] Failed syncing file in album: ${logFilename(i.file.path)}",
              e,
              stackTrace);
          return i;
        }
      } else {
        return i;
      }
    }).toList();
  }

  final AppDb appDb;

  static final _log = Logger("use_case.resync_album.ResyncAlbum");
}
