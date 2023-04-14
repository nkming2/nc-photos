import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/use_case/list_location_group.dart';

class CollectionLocationGroupProvider implements CollectionContentProvider {
  const CollectionLocationGroupProvider({
    required this.account,
    required this.location,
  });

  @override
  String get fourCc => "LOCG";

  @override
  String get id => location.place;

  @override
  int? get count => location.count;

  @override
  DateTime get lastModified => location.latestDateTime;

  @override
  List<CollectionCapability> get capabilities => [];

  @override
  CollectionItemSort get itemSort => CollectionItemSort.dateDescending;

  @override
  String? getCoverUrl(int width, int height) {
    return api_util.getFilePreviewUrlByFileId(
      account,
      location.latestFileId,
      width: width,
      height: height,
      isKeepAspectRatio: false,
    );
  }

  final Account account;
  final LocationGroup location;
}