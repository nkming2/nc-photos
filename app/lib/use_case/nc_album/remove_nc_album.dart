import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/nc_album.dart';

class RemoveNcAlbum {
  RemoveNcAlbum(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.ncAlbumRepo);

  Future<void> call(Account account, NcAlbum album) =>
      _c.ncAlbumRepo.remove(account, album);

  final DiContainer _c;
}
