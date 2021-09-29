import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';

class AddToAlbum {
  AddToAlbum(this.albumRepo);

  /// Add a list of AlbumItems to [album]
  Future<Album> call(
      Account account, Album album, List<AlbumItem> items) async {
    _log.info("[call] Add ${items.length} items to album '${album.name}'");
    assert(album.provider is AlbumStaticProvider);
    // resync is needed to work out album cover and latest item
    final oldItems = await PreProcessAlbum()(account, album);
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
    return newAlbum;
  }

  final AlbumRepo albumRepo;

  static final _log = Logger("use_case.add_to_album.AddToAlbum");
}
