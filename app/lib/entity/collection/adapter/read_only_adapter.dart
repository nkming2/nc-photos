import 'package:flutter/foundation.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:np_common/type.dart';

/// A read-only collection that does not support modifying its items
mixin CollectionReadOnlyAdapter implements CollectionAdapter {
  @override
  Future<int> addFiles(
    List<FileDescriptor> files, {
    ErrorWithValueHandler<FileDescriptor>? onError,
    required ValueChanged<Collection> onCollectionUpdated,
  }) {
    throw UnsupportedError("Operation not supported");
  }

  @override
  Future<Collection> edit({
    String? name,
    List<CollectionItem>? items,
    CollectionItemSort? itemSort,
  }) {
    throw UnsupportedError("Operation not supported");
  }

  @override
  Future<int> removeItems(
    List<CollectionItem> items, {
    ErrorWithValueIndexedHandler<CollectionItem>? onError,
    required ValueChanged<Collection> onCollectionUpdated,
  }) {
    throw UnsupportedError("Operation not supported");
  }

  @override
  bool isItemsRemovable(List<CollectionItem> items) {
    return false;
  }
}
