import 'package:copy_with/copy_with.dart';
import 'package:nc_photos/entity/collection_item/sorter.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:to_string/to_string.dart';

part 'collection.g.dart';

/// Describe a group of items
@genCopyWith
@toString
class Collection {
  const Collection({
    required this.name,
    required this.contentProvider,
  });

  @override
  String toString() => _$toString();

  bool compareIdentity(Collection other) => other.id == id;

  int get identityHashCode => id.hashCode;

  /// A unique id for each collection. The value is divided into two parts in
  /// the format XXXX-YYY...YYY, where XXXX is a four-character code
  /// representing the content provider type, and YYY is an implementation
  /// detail of each providers
  String get id => "${contentProvider.fourCc}-${contentProvider.id}";

  /// See [CollectionContentProvider.count]
  int? get count => contentProvider.count;

  /// See [CollectionContentProvider.lastModified]
  DateTime get lastModified => contentProvider.lastModified;

  /// See [CollectionContentProvider.capabilities]
  List<CollectionCapability> get capabilities => contentProvider.capabilities;

  /// See [CollectionContentProvider.itemSort]
  CollectionItemSort get itemSort => contentProvider.itemSort;

  /// See [CollectionContentProvider.getCoverUrl]
  String? getCoverUrl(int width, int height) =>
      contentProvider.getCoverUrl(width, height);

  CollectionSorter getSorter() => CollectionSorter.fromSortType(itemSort);

  final String name;
  final CollectionContentProvider contentProvider;
}

enum CollectionCapability {
  // add/remove items
  manualItem,
  // sort the items
  sort,
  // rearrange item manually
  manualSort,
  // can freely rename album
  rename,
  // text labels
  labelItem,
  // set the cover image
  manualCover,
}

/// Provide the actual content of a collection
abstract class CollectionContentProvider {
  const CollectionContentProvider();

  /// Unique FourCC of this provider type
  String get fourCc;

  /// Return the unique id of this collection
  String get id;

  /// Return the number of items in this collection, or null if not supported
  int? get count;

  /// Return the date time of this collection. Generally this is the date time
  /// of the latest child
  DateTime get lastModified;

  /// Return the capabilities of the collection
  ///
  /// Notice that the capabilities returned here represent all the capabilities
  /// that this implementation supports. In practice there may be extra runtime
  /// requirements that mask some of them (e.g., user permissions)
  List<CollectionCapability> get capabilities;

  /// Return the sort type
  CollectionItemSort get itemSort;

  /// Return the URL of the cover image if available
  ///
  /// The [width] and [height] are provided as a hint only, implementations are
  /// free to ignore them if it's not supported
  String? getCoverUrl(int width, int height);
}
