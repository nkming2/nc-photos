import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/nc_album.dart';
import 'package:nc_photos/entity/nc_album_item.dart';

class ListNcAlbumItem {
  ListNcAlbumItem(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.ncAlbumRepo);

  Stream<List<NcAlbumItem>> call(Account account, NcAlbum album) =>
      _c.ncAlbumRepo.getItems(account, album);

  final DiContainer _c;
}
