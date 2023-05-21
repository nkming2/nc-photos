import 'package:flutter/foundation.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/adapter.dart';
import 'package:nc_photos/entity/collection/util.dart';
import 'package:nc_photos/entity/collection_item.dart';
import 'package:nc_photos/entity/collection_item/util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/or_null.dart';
import 'package:np_common/ci_string.dart';
import 'package:np_common/type.dart';

/// A read-only collection that does not support modifying its items
mixin CollectionAdapterReadOnlyTag implements CollectionAdapter {
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
    OrNull<FileDescriptor>? cover,
    List<CollectionItem>? knownItems,
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
  bool isItemRemovable(CollectionItem item) => false;

  @override
  bool isManualCover() => false;

  @override
  Future<Collection?> updatePostLoad(List<CollectionItem> items) =>
      Future.value(null);
}

mixin CollectionAdapterUnremovableTag implements CollectionAdapter {
  @override
  Future<void> remove() {
    throw UnsupportedError("Operation not supported");
  }
}

mixin CollectionAdapterUnshareableTag implements CollectionAdapter {
  @override
  Future<CollectionShareResult> share(
    Sharee sharee, {
    required ValueChanged<Collection> onCollectionUpdated,
  }) {
    throw UnsupportedError("Operation not supported");
  }

  @override
  Future<CollectionShareResult> unshare(
    CiString userId, {
    required ValueChanged<Collection> onCollectionUpdated,
  }) {
    throw UnsupportedError("Operation not supported");
  }

  @override
  Future<Collection> importPendingShared() {
    throw UnsupportedError("Operation not supported");
  }
}
