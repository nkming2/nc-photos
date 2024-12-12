// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_photos2.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call(
      {List<FileDescriptor>? files,
      bool? isLoading,
      List<_Item>? transformedItems,
      Set<_Item>? selectedItems,
      DbFilesSummary? filesSummary,
      Set<_VisibleDate>? visibleDates,
      Set<Date>? queriedDates,
      bool? isEnableMemoryCollection,
      List<Collection>? memoryCollections,
      double? contentListMaxExtent,
      Progress? syncProgress,
      int? zoom,
      double? scale,
      double? viewWidth,
      double? viewHeight,
      int? itemPerRow,
      double? itemSize,
      bool? isScrolling,
      List<_MinimapItem>? minimapItems,
      double? minimapYRatio,
      Date? scrollDate,
      bool? hasMissingVideoPreview,
      double? bannerAdExtent,
      ExceptionEvent? error});
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call(
      {dynamic files,
      dynamic isLoading,
      dynamic transformedItems,
      dynamic selectedItems,
      dynamic filesSummary,
      dynamic visibleDates,
      dynamic queriedDates,
      dynamic isEnableMemoryCollection,
      dynamic memoryCollections,
      dynamic contentListMaxExtent = copyWithNull,
      dynamic syncProgress = copyWithNull,
      dynamic zoom,
      dynamic scale = copyWithNull,
      dynamic viewWidth = copyWithNull,
      dynamic viewHeight = copyWithNull,
      dynamic itemPerRow = copyWithNull,
      dynamic itemSize = copyWithNull,
      dynamic isScrolling,
      dynamic minimapItems = copyWithNull,
      dynamic minimapYRatio,
      dynamic scrollDate = copyWithNull,
      dynamic hasMissingVideoPreview,
      dynamic bannerAdExtent = copyWithNull,
      dynamic error = copyWithNull}) {
    return _State(
        files: files as List<FileDescriptor>? ?? that.files,
        isLoading: isLoading as bool? ?? that.isLoading,
        transformedItems:
            transformedItems as List<_Item>? ?? that.transformedItems,
        selectedItems: selectedItems as Set<_Item>? ?? that.selectedItems,
        filesSummary: filesSummary as DbFilesSummary? ?? that.filesSummary,
        visibleDates: visibleDates as Set<_VisibleDate>? ?? that.visibleDates,
        queriedDates: queriedDates as Set<Date>? ?? that.queriedDates,
        isEnableMemoryCollection:
            isEnableMemoryCollection as bool? ?? that.isEnableMemoryCollection,
        memoryCollections:
            memoryCollections as List<Collection>? ?? that.memoryCollections,
        contentListMaxExtent: contentListMaxExtent == copyWithNull
            ? that.contentListMaxExtent
            : contentListMaxExtent as double?,
        syncProgress: syncProgress == copyWithNull
            ? that.syncProgress
            : syncProgress as Progress?,
        zoom: zoom as int? ?? that.zoom,
        scale: scale == copyWithNull ? that.scale : scale as double?,
        viewWidth:
            viewWidth == copyWithNull ? that.viewWidth : viewWidth as double?,
        viewHeight: viewHeight == copyWithNull
            ? that.viewHeight
            : viewHeight as double?,
        itemPerRow:
            itemPerRow == copyWithNull ? that.itemPerRow : itemPerRow as int?,
        itemSize:
            itemSize == copyWithNull ? that.itemSize : itemSize as double?,
        isScrolling: isScrolling as bool? ?? that.isScrolling,
        minimapItems: minimapItems == copyWithNull
            ? that.minimapItems
            : minimapItems as List<_MinimapItem>?,
        minimapYRatio: minimapYRatio as double? ?? that.minimapYRatio,
        scrollDate:
            scrollDate == copyWithNull ? that.scrollDate : scrollDate as Date?,
        hasMissingVideoPreview:
            hasMissingVideoPreview as bool? ?? that.hasMissingVideoPreview,
        bannerAdExtent: bannerAdExtent == copyWithNull
            ? that.bannerAdExtent
            : bannerAdExtent as double?,
        error: error == copyWithNull ? that.error : error as ExceptionEvent?);
  }

  final _State that;
}

extension $_StateCopyWith on _State {
  $_StateCopyWithWorker get copyWith => _$copyWith;
  $_StateCopyWithWorker get _$copyWith => _$_StateCopyWithWorkerImpl(this);
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$_WrappedHomePhotosStateNpLog on _WrappedHomePhotosState {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2._WrappedHomePhotosState");
}

extension _$_BodyStateNpLog on _BodyState {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2._BodyState");
}

extension _$__NpLog on __ {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2.__");
}

extension _$_SelectionAppBarNpLog on _SelectionAppBar {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2._SelectionAppBar");
}

extension _$_SelectionAppBarMenuNpLog on _SelectionAppBarMenu {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2._SelectionAppBarMenu");
}

extension _$_BlocNpLog on _Bloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2._Bloc");
}

extension _$_MinimapViewNpLog on _MinimapView {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2._MinimapView");
}

extension _$_ContentListBodyNpLog on _ContentListBody {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.home_photos2._ContentListBody");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {files: [length: ${files.length}], isLoading: $isLoading, transformedItems: [length: ${transformedItems.length}], selectedItems: {length: ${selectedItems.length}}, filesSummary: $filesSummary, visibleDates: {length: ${visibleDates.length}}, queriedDates: {length: ${queriedDates.length}}, isEnableMemoryCollection: $isEnableMemoryCollection, memoryCollections: [length: ${memoryCollections.length}], contentListMaxExtent: ${contentListMaxExtent == null ? null : "${contentListMaxExtent!.toStringAsFixed(3)}"}, syncProgress: $syncProgress, zoom: $zoom, scale: ${scale == null ? null : "${scale!.toStringAsFixed(3)}"}, viewWidth: ${viewWidth == null ? null : "${viewWidth!.toStringAsFixed(3)}"}, viewHeight: ${viewHeight == null ? null : "${viewHeight!.toStringAsFixed(3)}"}, itemPerRow: $itemPerRow, itemSize: ${itemSize == null ? null : "${itemSize!.toStringAsFixed(3)}"}, isScrolling: $isScrolling, minimapItems: ${minimapItems == null ? null : "[length: ${minimapItems!.length}]"}, minimapYRatio: ${minimapYRatio.toStringAsFixed(3)}, scrollDate: $scrollDate, hasMissingVideoPreview: $hasMissingVideoPreview, bannerAdExtent: ${bannerAdExtent == null ? null : "${bannerAdExtent!.toStringAsFixed(3)}"}, error: $error}";
  }
}

extension _$_LoadItemsToString on _LoadItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_LoadItems {}";
  }
}

extension _$_RequestRefreshToString on _RequestRefresh {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_RequestRefresh {}";
  }
}

extension _$_TransformItemsToString on _TransformItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_TransformItems {files: [length: ${files.length}], summary: $summary}";
  }
}

extension _$_OnItemTransformedToString on _OnItemTransformed {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_OnItemTransformed {items: [length: ${items.length}], dates: {length: ${dates.length}}}";
  }
}

extension _$_SetSelectedItemsToString on _SetSelectedItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetSelectedItems {items: {length: ${items.length}}}";
  }
}

extension _$_AddSelectedItemsToCollectionToString
    on _AddSelectedItemsToCollection {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_AddSelectedItemsToCollection {collection: $collection}";
  }
}

extension _$_ArchiveSelectedItemsToString on _ArchiveSelectedItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ArchiveSelectedItems {}";
  }
}

extension _$_DeleteSelectedItemsToString on _DeleteSelectedItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_DeleteSelectedItems {}";
  }
}

extension _$_DownloadSelectedItemsToString on _DownloadSelectedItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_DownloadSelectedItems {}";
  }
}

extension _$_AddVisibleDateToString on _AddVisibleDate {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_AddVisibleDate {date: $date}";
  }
}

extension _$_RemoveVisibleDateToString on _RemoveVisibleDate {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_RemoveVisibleDate {date: $date}";
  }
}

extension _$_SetContentListMaxExtentToString on _SetContentListMaxExtent {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetContentListMaxExtent {value: ${value == null ? null : "${value!.toStringAsFixed(3)}"}}";
  }
}

extension _$_SetSyncProgressToString on _SetSyncProgress {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetSyncProgress {progress: $progress}";
  }
}

extension _$_StartScalingToString on _StartScaling {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_StartScaling {}";
  }
}

extension _$_EndScalingToString on _EndScaling {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_EndScaling {}";
  }
}

extension _$_SetScaleToString on _SetScale {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetScale {scale: ${scale.toStringAsFixed(3)}}";
  }
}

extension _$_StartScrollingToString on _StartScrolling {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_StartScrolling {}";
  }
}

extension _$_EndScrollingToString on _EndScrolling {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_EndScrolling {}";
  }
}

extension _$_SetLayoutConstraintToString on _SetLayoutConstraint {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetLayoutConstraint {viewWidth: ${viewWidth.toStringAsFixed(3)}, viewHeight: ${viewHeight.toStringAsFixed(3)}}";
  }
}

extension _$_TransformMinimapToString on _TransformMinimap {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_TransformMinimap {}";
  }
}

extension _$_UpdateScrollDateToString on _UpdateScrollDate {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_UpdateScrollDate {}";
  }
}

extension _$_SetEnableMemoryCollectionToString on _SetEnableMemoryCollection {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetEnableMemoryCollection {value: $value}";
  }
}

extension _$_UpdateDateTimeGroupToString on _UpdateDateTimeGroup {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_UpdateDateTimeGroup {}";
  }
}

extension _$_UpdateMemoriesToString on _UpdateMemories {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_UpdateMemories {}";
  }
}

extension _$_TripMissingVideoPreviewToString on _TripMissingVideoPreview {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_TripMissingVideoPreview {}";
  }
}

extension _$_UpdateBannerAdExtentToString on _UpdateBannerAdExtent {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_UpdateBannerAdExtent {value: ${value == null ? null : "${value!.toStringAsFixed(3)}"}}";
  }
}

extension _$_SetErrorToString on _SetError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetError {error: $error, stackTrace: $stackTrace}";
  }
}

extension _$_VisibleDateToString on _VisibleDate {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_VisibleDate {id: $id, date: $date}";
  }
}

extension _$_ArchiveFailedErrorToString on _ArchiveFailedError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ArchiveFailedError {count: $count}";
  }
}

extension _$_RemoveFailedErrorToString on _RemoveFailedError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_RemoveFailedError {count: $count}";
  }
}
