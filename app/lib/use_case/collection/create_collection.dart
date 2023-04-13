import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/content_provider/album.dart';
import 'package:nc_photos/entity/collection/content_provider/nc_album.dart';
import 'package:nc_photos/use_case/album/create_album.dart';
import 'package:nc_photos/use_case/nc_album/create_nc_album.dart';

class CreateCollection {
  CreateCollection(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.albumRepo) && CreateNcAlbum.require(c);

  Future<Collection> call(Account account, Collection collection) async {
    final provider = collection.contentProvider;
    if (provider is CollectionNcAlbumProvider) {
      await CreateNcAlbum(_c)(account, provider.album);
      return collection;
    } else if (provider is CollectionAlbumProvider) {
      final album = await CreateAlbum(_c.albumRepo)(account, provider.album);
      return collection.copyWith(
        contentProvider: CollectionAlbumProvider(
          account: account,
          album: album,
        ),
      );
    } else {
      throw UnimplementedError("Unknown type: ${provider.runtimeType}");
    }
  }

  final DiContainer _c;
}
