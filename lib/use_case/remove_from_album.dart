import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/resync_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';

class RemoveFromAlbum {
  RemoveFromAlbum(this.albumRepo);

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
    // check if any of the removed items was the latest item
    if (items.whereType<AlbumFileItem>().any((element) =>
        element.file.bestDateTime == album.provider.latestItemTime)) {
      _log.info("[call] Resync as latest item is being removed");
      // need to update the album properties
      final newItemsSynced = await ResyncAlbum()(account, newAlbum);
      newAlbum = await UpdateAlbumWithActualItems(null)(
        account,
        newAlbum,
        newItemsSynced,
      );
    }
    await UpdateAlbum(albumRepo)(account, newAlbum);
    return newAlbum;
  }

  final AlbumRepo albumRepo;

  static final _log = Logger("use_case.remove_from_album.RemoveFromAlbum");
}
