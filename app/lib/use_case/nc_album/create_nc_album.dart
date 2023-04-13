import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/nc_album.dart';

class CreateNcAlbum {
  CreateNcAlbum(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.ncAlbumRepo);

  Future<void> call(Account account, NcAlbum album) =>
      _c.ncAlbumRepo.create(account, album);

  final DiContainer _c;
}
