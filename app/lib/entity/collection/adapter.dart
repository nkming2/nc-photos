import 'package:flutter/foundation.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter/album.dart';
import 'package:nc_photos/entity/collection/adapter/location_group.dart';
import 'package:nc_photos/entity/collection/adapter/nc_album.dart';
import 'package:nc_photos/entity/collection/adapter/person.dart';
import 'package:nc_photos/entity/collection/adapter/tag.dart';
import 'package:nc_photos/entity/collection/content_provider/album.dart';
import 'package:nc_photos/entity/collection/content_provider/location_group.dart';
import 'package:nc_photos/entity/collection/content_provider/nc_album.dart';
import 'package:nc_photos/entity/collection/content_provider/person.dart';
import 'package:nc_photos/entity/collection/content_provider/tag.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/new_item.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:np_common/type.dart';

abstract class CollectionAdapter {
  const CollectionAdapter();

  static CollectionAdapter of(
      DiContainer c, Account account, Collection collection) {
    switch (collection.contentProvider.runtimeType) {
      case CollectionAlbumProvider:
        return CollectionAlbumAdapter(c, account, collection);
      case CollectionLocationGroupProvider:
        return CollectionLocationGroupAdapter(c, account, collection);
      case CollectionNcAlbumProvider:
        return CollectionNcAlbumAdapter(c, account, collection);
      case CollectionPersonProvider:
        return CollectionPersonAdapter(c, account, collection);
      case CollectionTagProvider:
        return CollectionTagAdapter(c, account, collection);
      default:
        throw UnsupportedError(
            "Unknown type: ${collection.contentProvider.runtimeType}");
    }
  }

  /// List items inside this collection
  Stream<List<CollectionItem>> listItem();

  /// Add [files] to this collection and return the added count
  Future<int> addFiles(
    List<FileDescriptor> files, {
    ErrorWithValueHandler<FileDescriptor>? onError,
    required ValueChanged<Collection> onCollectionUpdated,
  });

  /// Edit this collection
  ///
  /// [name] and [items] are optional params and if not null, set the value to
  /// this collection
  Future<Collection> edit({
    String? name,
    List<CollectionItem>? items,
    CollectionItemSort? itemSort,
  });

  /// Remove [items] from this collection and return the removed count
  Future<int> removeItems(
    List<CollectionItem> items, {
    ErrorWithValueIndexedHandler<CollectionItem>? onError,
    required ValueChanged<Collection> onCollectionUpdated,
  });

  /// Convert a [NewCollectionItem] to an adapted one
  Future<CollectionItem> adaptToNewItem(NewCollectionItem original);

  bool isItemsRemovable(List<CollectionItem> items);

  /// Remove this collection
  Future<void> remove();
}

abstract class CollectionItemAdapter {
  const CollectionItemAdapter();

  CollectionItem toItem();
}
