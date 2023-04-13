import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/util.dart';

class EditCollection {
  const EditCollection(this._c);

  /// Edit a [collection]
  ///
  /// This use case support the following operations (implementations may only
  /// support a subset of the below operations):
  /// - Rename (set [name])
  /// - Add text label(s) (set [items])
  /// - Sort [items] (set [items] and/or [itemSort])
  ///
  /// \* To add files to a collection, use [AddFileToCollection] instead
  Future<Collection> call(
    Account account,
    Collection collection, {
    String? name,
    List<CollectionItem>? items,
    CollectionItemSort? itemSort,
  }) =>
      CollectionAdapter.of(_c, account, collection).edit(
        name: name,
        items: items,
        itemSort: itemSort,
      );

  final DiContainer _c;
}
