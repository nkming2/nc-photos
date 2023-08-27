import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';

class CreateAlbum {
  const CreateAlbum(this.albumRepo);

  Future<Album> call(Account account, Album album) async =>
      albumRepo.create(account, album);

  final AlbumRepo albumRepo;
}
