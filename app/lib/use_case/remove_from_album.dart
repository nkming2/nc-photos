import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/use_case/unshare_file_from_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';

class RemoveFromAlbum {
  RemoveFromAlbum(this._c)
      : assert(require(_c)),
        assert(UnshareFileFromAlbum.require(_c)),
        assert(PreProcessAlbum.require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.albumRepo);

  /// Remove a list of AlbumItems from [album]
  ///
  /// The items are compared with [identical], so it must come from [album] for
  /// it to work
  ///
  /// If [shouldUnshare] is false, files will not be unshared after removing
  /// from the album
  Future<Album> call(
    Account account,
    Album album,
    List<AlbumItem> items, {
    bool shouldUnshare = true,
  }) async {
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
    await UpdateAlbum(_c.albumRepo)(account, newAlbum);

    if (!shouldUnshare) {
      _log.info("[call] Skip unsharing files");
    } else {
      if (album.shares?.isNotEmpty == true) {
        final removeFiles =
            items.whereType<AlbumFileItem>().map((e) => e.file).toList();
        if (removeFiles.isNotEmpty) {
          await _unshareFiles(account, newAlbum, removeFiles);
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
    final newItemsSynced = await PreProcessAlbum(_c)(account, newAlbum);
    newAlbum = await UpdateAlbumWithActualItems(null)(
      account,
      newAlbum,
      newItemsSynced,
    );
    return newAlbum;
  }

  Future<void> _unshareFiles(
      Account account, Album album, List<File> files) async {
    final albumShares = (album.shares!.map((e) => e.userId).toList()
          ..add(album.albumFile!.ownerId ?? account.username))
        .where((element) => element != account.username)
        .toList();
    if (albumShares.isNotEmpty) {
      await UnshareFileFromAlbum(_c)(account, album, files, albumShares);
    }
  }

  final DiContainer _c;

  static final _log = Logger("use_case.remove_from_album.RemoveFromAlbum");
}
