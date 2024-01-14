part of '../home_photos2.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.files,
    required this.isLoading,
    required this.transformedItems,
    required this.selectedItems,
    required this.visibleItems,
    required this.isEnableMemoryCollection,
    required this.memoryCollections,
    this.contentListMaxExtent,
    this.syncProgress,
    required this.zoom,
    this.scale,
    this.error,
  });

  factory _State.init({
    required bool isEnableMemoryCollection,
    required int zoom,
  }) =>
      _State(
        files: const [],
        isLoading: false,
        transformedItems: const [],
        selectedItems: const {},
        visibleItems: const {},
        isEnableMemoryCollection: isEnableMemoryCollection,
        memoryCollections: const [],
        zoom: zoom,
      );

  @override
  String toString() => _$toString();

  final List<FileDescriptor> files;
  final bool isLoading;
  final List<_Item> transformedItems;
  final Set<_Item> selectedItems;
  final Set<_VisibleItem> visibleItems;

  final bool isEnableMemoryCollection;
  final List<Collection> memoryCollections;

  final double? contentListMaxExtent;
  final Progress? syncProgress;

  final int zoom;
  final double? scale;

  final ExceptionEvent? error;
}

abstract class _Event {}

/// Load the files
@toString
class _LoadItems implements _Event {
  const _LoadItems();

  @override
  String toString() => _$toString();
}

@toString
class _Reload implements _Event {
  const _Reload();

  @override
  String toString() => _$toString();
}

/// Transform the file list (e.g., filtering, sorting, etc)
@toString
class _TransformItems implements _Event {
  const _TransformItems(this.items);

  @override
  String toString() => _$toString();

  final List<FileDescriptor> items;
}

@toString
class _OnItemTransformed implements _Event {
  const _OnItemTransformed(this.items, this.memoryCollections);

  @override
  String toString() => _$toString();

  final List<_Item> items;
  final List<Collection> memoryCollections;
}

/// Set the currently selected items
@toString
class _SetSelectedItems implements _Event {
  const _SetSelectedItems({
    required this.items,
  });

  @override
  String toString() => _$toString();

  final Set<_Item> items;
}

@toString
class _AddSelectedItemsToCollection implements _Event {
  const _AddSelectedItemsToCollection(this.collection);

  @override
  String toString() => _$toString();

  final Collection collection;
}

@toString
class _ArchiveSelectedItems implements _Event {
  const _ArchiveSelectedItems();

  @override
  String toString() => _$toString();
}

@toString
class _DeleteSelectedItems implements _Event {
  const _DeleteSelectedItems();

  @override
  String toString() => _$toString();
}

@toString
class _DownloadSelectedItems implements _Event {
  const _DownloadSelectedItems();

  @override
  String toString() => _$toString();
}

@toString
class _AddVisibleItem implements _Event {
  const _AddVisibleItem(this.item);

  @override
  String toString() => _$toString();

  final _VisibleItem item;
}

@toString
class _RemoveVisibleItem implements _Event {
  const _RemoveVisibleItem(this.item);

  @override
  String toString() => _$toString();

  final _VisibleItem item;
}

@toString
class _SetContentListMaxExtent implements _Event {
  const _SetContentListMaxExtent(this.value);

  @override
  String toString() => _$toString();

  final double? value;
}

@toString
class _SetSyncProgress implements _Event {
  const _SetSyncProgress(this.progress);

  @override
  String toString() => _$toString();

  final Progress? progress;
}

@toString
class _StartScaling implements _Event {
  const _StartScaling();

  @override
  String toString() => _$toString();
}

@toString
class _EndScaling implements _Event {
  const _EndScaling();

  @override
  String toString() => _$toString();
}

@toString
class _SetScale implements _Event {
  const _SetScale(this.scale);

  @override
  String toString() => _$toString();

  final double scale;
}

@toString
class _SetEnableMemoryCollection implements _Event {
  const _SetEnableMemoryCollection(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}

@toString
class _SetSortByName implements _Event {
  const _SetSortByName(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}

@toString
class _SetMemoriesRange implements _Event {
  const _SetMemoriesRange(this.value);

  @override
  String toString() => _$toString();

  final int value;
}

@toString
class _SetEnableExif implements _Event {
  const _SetEnableExif(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}

@toString
class _SetShareFolder implements _Event {
  const _SetShareFolder(this.value);

  @override
  String toString() => _$toString();

  final String value;
}

@toString
class _UpdateDateTimeGroup implements _Event {
  const _UpdateDateTimeGroup();

  @override
  String toString() => _$toString();
}

@toString
class _SetError implements _Event {
  const _SetError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
