import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/create_share.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';

class AddToAlbum {
  const AddToAlbum(this.albumRepo, this.shareRepo, this.appDb, this.pref);

  /// Add a list of AlbumItems to [album]
  Future<Album> call(
      Account account, Album album, List<AlbumItem> items) async {
    _log.info("[call] Add ${items.length} items to album '${album.name}'");
    assert(album.provider is AlbumStaticProvider);
    // resync is needed to work out album cover and latest item
    final oldItems = await PreProcessAlbum(appDb)(account, album);
    final newItems = makeDistinctAlbumItems([
      ...items,
      ...oldItems,
    ]);
    var newAlbum = album.copyWith(
      provider: AlbumStaticProvider.of(album).copyWith(
        items: newItems,
      ),
    );
    // UpdateAlbumWithActualItems only persists when there are changes to
    // several properties, so we can't rely on it
    newAlbum = await UpdateAlbumWithActualItems(null)(
      account,
      newAlbum,
      newItems,
    );
    await UpdateAlbum(albumRepo)(account, newAlbum);

    if (pref.isLabEnableSharedAlbumOr(false)) {
      final newFiles =
          items.whereType<AlbumFileItem>().map((e) => e.file).toList();
      if (newFiles.isNotEmpty) {
        await _shareFiles(account, newAlbum, newFiles);
      }
    }

    return newAlbum;
  }

  Future<void> _shareFiles(
      Account account, Album album, List<File> files) async {
    try {
      final albumShares =
          (await ListShare(shareRepo)(account, album.albumFile!))
              .where((element) => element.shareType == ShareType.user)
              .map((e) => e.shareWith!)
              .toSet();
      if (albumShares.isEmpty) {
        return;
      }
      for (final f in files) {
        try {
          final fileShares = (await ListShare(shareRepo)(account, f))
              .where((element) => element.shareType == ShareType.user)
              .map((e) => e.shareWith!)
              .toSet();
          final diffShares = albumShares.difference(fileShares);
          for (final s in diffShares) {
            try {
              await CreateUserShare(shareRepo)(account, f, s);
            } catch (e, stackTrace) {
              _log.shout(
                  "[_shareFiles] Failed while CreateUserShare: ${logFilename(f.path)}",
                  e,
                  stackTrace);
            }
          }
        } catch (e, stackTrace) {
          _log.shout(
              "[_shareFiles] Failed while listing shares: ${logFilename(f.path)}",
              e,
              stackTrace);
        }
      }
    } catch (e, stackTrace) {
      _log.shout(
          "[_shareFiles] Failed while listing album shares: ${logFilename(album.albumFile?.path)}",
          e,
          stackTrace);
    }
  }

  final AlbumRepo albumRepo;
  final ShareRepo shareRepo;
  final AppDb appDb;
  final Pref pref;

  static final _log = Logger("use_case.add_to_album.AddToAlbum");
}
