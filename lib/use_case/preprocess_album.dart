import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/use_case/populate_album.dart';
import 'package:nc_photos/use_case/resync_album.dart';

/// Pre-process an album such that it's ready to be displayed
///
/// Internally, it'll dispatch the work depending on the album:
/// - with AlbumStaticProvider: [ResyncAlbum]
/// - with AlbumDirProvider: [PopulateAlbum]
class PreProcessAlbum {
  const PreProcessAlbum(this.appDb);

  Future<List<AlbumItem>> call(Account account, Album album) {
    if (album.provider is AlbumStaticProvider) {
      return ResyncAlbum(appDb)(account, album);
    } else if (album.provider is AlbumDynamicProvider ||
        album.provider is AlbumSmartProvider) {
      return PopulateAlbum(appDb)(account, album);
    } else {
      throw ArgumentError(
          "Unknown album provider: ${album.provider.runtimeType}");
    }
  }

  final AppDb appDb;
}
