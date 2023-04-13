import 'package:clock/clock.dart';
import 'package:copy_with/copy_with.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/nc_album.dart';
import 'package:to_string/to_string.dart';

part 'nc_album.g.dart';

/// Album provided by our app
@genCopyWith
@toString
class CollectionNcAlbumProvider implements CollectionContentProvider {
  const CollectionNcAlbumProvider({
    required this.account,
    required this.album,
  });

  @override
  String toString() => _$toString();

  @override
  String get fourCc => "NC25";

  @override
  String get id => album.path;

  @override
  int? get count => album.count;

  @override
  DateTime get lastModified => album.dateEnd ?? clock.now().toUtc();

  @override
  List<CollectionCapability> get capabilities => [
        CollectionCapability.manualItem,
        CollectionCapability.rename,
      ];

  @override
  CollectionItemSort get itemSort => CollectionItemSort.dateDescending;

  @override
  String? getCoverUrl(int width, int height) {
    if (album.lastPhoto == null) {
      return null;
    } else {
      return api_util.getFilePreviewUrlByFileId(
        account,
        album.lastPhoto!,
        width: width,
        height: height,
        isKeepAspectRatio: false,
      );
    }
  }

  final Account account;
  final NcAlbum album;
}
