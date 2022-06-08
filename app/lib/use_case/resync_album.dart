import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';

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
    final dbItems = await appDb.use(
      (db) => db.transaction(AppDb.file2StoreName, idbModeReadOnly),
      (transaction) async {
        final store = transaction.objectStore(AppDb.file2StoreName);
        return await Future.wait(items.whereType<AlbumFileItem>().map((i) =>
            store.getObject(
                AppDbFile2Entry.toPrimaryKey(account, i.file.fileId!))));
      },
    );
    final fileMap = await compute(_covertFileMap, dbItems);
    return items.map((i) {
      if (i is AlbumFileItem) {
        try {
          return i.copyWith(
            file: fileMap[i.file.fileId]!,
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

Map<int, File> _covertFileMap(List<Object?> dbItems) {
  return Map.fromEntries(dbItems
      .whereType<Map>()
      .map((j) => AppDbFile2Entry.fromJson(j.cast<String, dynamic>()).file)
      .map((f) => MapEntry(f.fileId!, f)));
}
