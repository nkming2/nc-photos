import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/exception.dart';

class UpdateAlbum {
  UpdateAlbum(this.albumRepo);

  Future<void> call(Account account, Album album) async {
    if (album.savedVersion > Album.version) {
      // the album is created by a newer version of this app
      throw AlbumDowngradeException(
          "Not allowed to downgrade album '${album.name}'");
    }
    final provider = album.provider;
    if (provider is AlbumStaticProvider) {
      await albumRepo.update(
        account,
        album.copyWith(
          provider: provider.copyWith(
            items: _minimizeItems(provider.items),
          ),
        ),
      );
    } else {
      await albumRepo.update(account, album);
    }
  }

  List<AlbumItem> _minimizeItems(List<AlbumItem> items) {
    return items.map((e) => e is AlbumFileItem ? e.minimize() : e).toList();
  }

  final AlbumRepo albumRepo;
}
