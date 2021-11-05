import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/use_case/unshare_file_from_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';

class RemoveFromAlbum {
  const RemoveFromAlbum(
      this.albumRepo, this.shareRepo, this.fileRepo, this.appDb, this.pref);

  /// Remove a list of AlbumItems from [album]
  ///
  /// The items are compared with [identical], so it must come from [album] for
  /// it to work
  Future<Album> call(
      Account account, Album album, List<AlbumItem> items) async {
    _log.info("[call] Remove ${items.length} items from album '${album.name}'");
    assert(album.provider is AlbumStaticProvider);
    final provider = album.provider as AlbumStaticProvider;
    final newItems = provider.items
        .where((element) => !items.containsIdentical(element))
        .toList();
    var newAlbum = album.copyWith(
      provider: AlbumStaticProvider.of(album).copyWith(
        items: newItems,
      ),
    );
    newAlbum = await _fixAlbumPostRemove(account, newAlbum, items);
    await UpdateAlbum(albumRepo)(account, newAlbum);

    if (pref.isLabEnableSharedAlbumOr(false)) {
      final removeFiles =
          items.whereType<AlbumFileItem>().map((e) => e.file).toList();
      if (removeFiles.isNotEmpty) {
        final albumShares =
            (await ListShare(shareRepo)(account, newAlbum.albumFile!))
                .where((element) => element.shareType == ShareType.user)
                .map((e) => e.shareWith!)
                .toList();
        if (albumShares.isNotEmpty) {
          await UnshareFileFromAlbum(shareRepo, fileRepo, albumRepo)(
              account, newAlbum, removeFiles, albumShares);
        }
      }
    }

    return newAlbum;
  }

  /// Update the album accordingly if any of the removed items is interesting
  /// (e.g., cover, latest item, etc)
  Future<Album> _fixAlbumPostRemove(
      Account account, Album newAlbum, List<AlbumItem> items) async {
    bool isNeedUpdate = false;
    for (final fileItem in items.whereType<AlbumFileItem>()) {
      if (newAlbum.coverProvider
              .getCover(newAlbum)
              ?.compareServerIdentity(fileItem.file) ==
          true) {
        // revert to auto cover so [UpdateAutoAlbumCover] can do its work
        newAlbum = newAlbum.copyWith(
          coverProvider: AlbumAutoCoverProvider(),
        );
        isNeedUpdate = true;
        break;
      }
      if (fileItem.file.bestDateTime == newAlbum.provider.latestItemTime) {
        isNeedUpdate = true;
        break;
      }
    }
    if (!isNeedUpdate) {
      return newAlbum;
    }

    _log.info(
        "[_fixAlbumPostRemove] Resync as interesting item is being removed");
    // need to update the album properties
    final newItemsSynced = await PreProcessAlbum(appDb)(account, newAlbum);
    newAlbum = await UpdateAlbumWithActualItems(null)(
      account,
      newAlbum,
      newItemsSynced,
    );
    return newAlbum;
  }

  final AlbumRepo albumRepo;
  final ShareRepo shareRepo;
  final FileRepo fileRepo;
  final AppDb appDb;
  final Pref pref;

  static final _log = Logger("use_case.remove_from_album.RemoveFromAlbum");
}
