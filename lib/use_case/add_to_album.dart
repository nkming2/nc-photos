import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/use_case/update_album.dart';

class AddToAlbum {
  AddToAlbum(this.albumRepo);

  /// Add a list of AlbumItems to [album]
  Future<void> call(Account account, Album album, List<AlbumItem> items) =>
      UpdateAlbum(albumRepo)(
          account,
          album.copyWith(
            provider: AlbumStaticProvider(
              items: makeDistinctAlbumItems([
                ...items,
                ...AlbumStaticProvider.of(album).items,
              ]),
            ),
          ));

  final AlbumRepo albumRepo;
}
