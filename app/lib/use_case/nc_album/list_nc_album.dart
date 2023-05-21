import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/nc_album.dart';

class ListNcAlbum {
  ListNcAlbum(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.ncAlbumRepo);

  /// List all [NcAlbum]s belonging to [account]
  Stream<List<NcAlbum>> call(Account account) =>
      _c.ncAlbumRepo.getAlbums(account);

  final DiContainer _c;
}
