// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_browser.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call(
      {Collection? collection,
      String? coverUrl,
      List<CollectionItem>? items,
      bool? isLoading,
      List<_Item>? transformedItems,
      Set<_Item>? selectedItems,
      bool? isSelectionRemovable,
      bool? isSelectionManageableFile,
      bool? isEditMode,
      bool? isEditBusy,
      String? editName,
      List<CollectionItem>? editItems,
      List<_Item>? editTransformedItems,
      CollectionItemSort? editSort,
      bool? isDragging,
      ExceptionEvent? error,
      String? message});
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call(
      {dynamic collection,
      dynamic coverUrl = copyWithNull,
      dynamic items,
      dynamic isLoading,
      dynamic transformedItems,
      dynamic selectedItems,
      dynamic isSelectionRemovable,
      dynamic isSelectionManageableFile,
      dynamic isEditMode,
      dynamic isEditBusy,
      dynamic editName = copyWithNull,
      dynamic editItems = copyWithNull,
      dynamic editTransformedItems = copyWithNull,
      dynamic editSort = copyWithNull,
      dynamic isDragging,
      dynamic error = copyWithNull,
      dynamic message = copyWithNull}) {
    return _State(
        collection: collection as Collection? ?? that.collection,
        coverUrl:
            coverUrl == copyWithNull ? that.coverUrl : coverUrl as String?,
        items: items as List<CollectionItem>? ?? that.items,
        isLoading: isLoading as bool? ?? that.isLoading,
        transformedItems:
            transformedItems as List<_Item>? ?? that.transformedItems,
        selectedItems: selectedItems as Set<_Item>? ?? that.selectedItems,
        isSelectionRemovable:
            isSelectionRemovable as bool? ?? that.isSelectionRemovable,
        isSelectionManageableFile: isSelectionManageableFile as bool? ??
            that.isSelectionManageableFile,
        isEditMode: isEditMode as bool? ?? that.isEditMode,
        isEditBusy: isEditBusy as bool? ?? that.isEditBusy,
        editName:
            editName == copyWithNull ? that.editName : editName as String?,
        editItems: editItems == copyWithNull
            ? that.editItems
            : editItems as List<CollectionItem>?,
        editTransformedItems: editTransformedItems == copyWithNull
            ? that.editTransformedItems
            : editTransformedItems as List<_Item>?,
        editSort: editSort == copyWithNull
            ? that.editSort
            : editSort as CollectionItemSort?,
        isDragging: isDragging as bool? ?? that.isDragging,
        error: error == copyWithNull ? that.error : error as ExceptionEvent?,
        message: message == copyWithNull ? that.message : message as String?);
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

extension _$_WrappedCollectionBrowserStateNpLog
    on _WrappedCollectionBrowserState {
  // ignore: unused_element
  Logger get _log => log;

  static final log =
      Logger("widget.collection_browser._WrappedCollectionBrowserState");
}

extension _$_SelectionAppBarNpLog on _SelectionAppBar {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.collection_browser._SelectionAppBar");
}

extension _$_BlocNpLog on _Bloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.collection_browser._Bloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {collection: $collection, coverUrl: $coverUrl, items: [length: ${items.length}], isLoading: $isLoading, transformedItems: [length: ${transformedItems.length}], selectedItems: $selectedItems, isSelectionRemovable: $isSelectionRemovable, isSelectionManageableFile: $isSelectionManageableFile, isEditMode: $isEditMode, isEditBusy: $isEditBusy, editName: $editName, editItems: ${editItems == null ? null : "[length: ${editItems!.length}]"}, editTransformedItems: ${editTransformedItems == null ? null : "[length: ${editTransformedItems!.length}]"}, editSort: ${editSort == null ? null : "${editSort!.name}"}, isDragging: $isDragging, error: $error, message: $message}";
  }
}

extension _$_UpdateCollectionToString on _UpdateCollection {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_UpdateCollection {collection: $collection}";
  }
}

extension _$_LoadItemsToString on _LoadItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_LoadItems {}";
  }
}

extension _$_TransformItemsToString on _TransformItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_TransformItems {items: [length: ${items.length}]}";
  }
}

extension _$_DownloadToString on _Download {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_Download {}";
  }
}

extension _$_BeginEditToString on _BeginEdit {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_BeginEdit {}";
  }
}

extension _$_EditNameToString on _EditName {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_EditName {name: $name}";
  }
}

extension _$_AddLabelToCollectionToString on _AddLabelToCollection {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_AddLabelToCollection {label: $label}";
  }
}

extension _$_EditSortToString on _EditSort {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_EditSort {sort: ${sort.name}}";
  }
}

extension _$_EditManualSortToString on _EditManualSort {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_EditManualSort {sorted: [length: ${sorted.length}]}";
  }
}

extension _$_TransformEditItemsToString on _TransformEditItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_TransformEditItems {items: [length: ${items.length}]}";
  }
}

extension _$_DoneEditToString on _DoneEdit {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_DoneEdit {}";
  }
}

extension _$_CancelEditToString on _CancelEdit {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_CancelEdit {}";
  }
}

extension _$_UnsetCoverToString on _UnsetCover {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_UnsetCover {}";
  }
}

extension _$_SetSelectedItemsToString on _SetSelectedItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetSelectedItems {items: $items}";
  }
}

extension _$_DownloadSelectedItemsToString on _DownloadSelectedItems {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_DownloadSelectedItems {}";
  }
}

extension _$_AddSelectedItemsToCollectionToString
    on _AddSelectedItemsToCollection {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_AddSelectedItemsToCollection {collection: $collection}";
  }
}

extension _$_RemoveSelectedItemsFromCollectionToString
    on _RemoveSelectedItemsFromCollection {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_RemoveSelectedItemsFromCollection {}";
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

extension _$_SetDraggingToString on _SetDragging {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetDragging {flag: $flag}";
  }
}

extension _$_SetErrorToString on _SetError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetError {error: $error, stackTrace: $stackTrace}";
  }
}

extension _$_SetMessageToString on _SetMessage {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetMessage {message: $message}";
  }
}
