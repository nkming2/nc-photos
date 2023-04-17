import 'package:copy_with/copy_with.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:to_string/to_string.dart';

part 'album.g.dart';

/// Album provided by our app
@genCopyWith
@toString
class CollectionAlbumProvider implements CollectionContentProvider {
  const CollectionAlbumProvider({
    required this.account,
    required this.album,
  });

  @override
  String toString() => _$toString();

  @override
  String get fourCc => "ALBM";

  @override
  String get id => album.albumFile!.fileId!.toString();

  @override
  int? get count {
    if (album.provider is AlbumStaticProvider) {
      return (album.provider as AlbumStaticProvider).items.length;
    } else {
      return null;
    }
  }

  @override
  DateTime get lastModified =>
      album.provider.latestItemTime ?? album.lastUpdated;

  @override
  List<CollectionCapability> get capabilities => [
        CollectionCapability.sort,
        CollectionCapability.rename,
        CollectionCapability.manualCover,
        if (album.provider is AlbumStaticProvider) ...[
          CollectionCapability.manualItem,
          CollectionCapability.manualSort,
          CollectionCapability.labelItem,
        ],
      ];

  /// Capabilities when this album is shared to this user by someone else
  List<CollectionCapability> get guestCapabilities => [
        if (album.provider is AlbumStaticProvider) ...[
          CollectionCapability.manualItem,
          CollectionCapability.labelItem,
        ],
      ];

  @override
  CollectionItemSort get itemSort => album.sortProvider.toCollectionItemSort();

  @override
  String? getCoverUrl(int width, int height) {
    final fd = album.coverProvider.getCover(album);
    if (fd == null) {
      return null;
    } else {
      return api_util.getFilePreviewUrlByFileId(
        account,
        fd.fdId,
        width: width,
        height: height,
        isKeepAspectRatio: false,
      );
    }
  }

  final Account account;
  final Album album;
}
