import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:np_codegen/np_codegen.dart';

part 'edit_album.g.dart';

@npLog
class EditAlbum {
  const EditAlbum(this._c);

  /// Modify an [album]
  Future<Album> call(
    Account account,
    Album album, {
    String? name,
    List<AlbumItem>? items,
    CollectionItemSort? itemSort,
  }) async {
    _log.info(
        "[call] Edit album ${album.name}, name: $name, items: $items, itemSort: $itemSort");
    var newAlbum = album;
    if (name != null) {
      newAlbum = newAlbum.copyWith(name: name);
    }
    if (items != null) {
      if (album.provider is AlbumStaticProvider) {
        newAlbum = newAlbum.copyWith(
          provider: (album.provider as AlbumStaticProvider).copyWith(
            items: items,
          ),
        );
      }
    }
    if (itemSort != null) {
      newAlbum = newAlbum.copyWith(
        sortProvider: AlbumSortProvider.fromCollectionItemSort(itemSort),
      );
    }
    if (identical(newAlbum, album)) {
      return album;
    }
    await UpdateAlbum(_c.albumRepo)(account, newAlbum);
    return newAlbum;
  }

  final DiContainer _c;
}
