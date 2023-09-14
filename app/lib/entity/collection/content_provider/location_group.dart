import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/util.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/use_case/list_location_group.dart';

class CollectionLocationGroupProvider
    with EquatableMixin
    implements CollectionContentProvider {
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
  List<CollectionCapability> get capabilities => [
        CollectionCapability.deleteItem,
      ];

  @override
  CollectionItemSort get itemSort => CollectionItemSort.dateDescending;

  @override
  List<CollectionShare> get shares => [];

  @override
  String? getCoverUrl(
    int width,
    int height, {
    bool? isKeepAspectRatio,
  }) {
    return api_util.getFilePreviewUrlByFileId(
      account,
      location.latestFileId,
      width: width,
      height: height,
      isKeepAspectRatio: isKeepAspectRatio ?? false,
    );
  }

  @override
  bool get isDynamicCollection => true;

  @override
  bool get isPendingSharedAlbum => false;

  @override
  bool get isOwned => true;

  @override
  List<Object?> get props => [account, location];

  final Account account;
  final LocationGroup location;
}
