part of '../home_collections.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.collections,
    required this.sort,
    required this.isLoading,
    required this.transformedItems,
    required this.selectedItems,
    this.error,
    required this.removeError,
  });

  factory _State.init() {
    return const _State(
      collections: [],
      sort: collection_util.CollectionSort.dateDescending,
      isLoading: false,
      transformedItems: [],
      selectedItems: {},
      removeError: null,
    );
  }

  @override
  String toString() => _$toString();

  final List<Collection> collections;
  final collection_util.CollectionSort sort;
  final bool isLoading;
  final List<_Item> transformedItems;
  final Set<_Item> selectedItems;

  final ExceptionEvent? error;
  final ExceptionEvent? removeError;
}

abstract class _Event {
  const _Event();
}

/// Load the list of collections belonging to this account
@toString
class _LoadCollections implements _Event {
  const _LoadCollections();

  @override
  String toString() => _$toString();
}

/// Transform the collection list (e.g., filtering, sorting, etc)
@toString
class _TransformItems implements _Event {
  const _TransformItems(this.collections);

  @override
  String toString() => _$toString();

  final List<Collection> collections;
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

/// Delete selected items
@toString
class _RemoveSelectedItems implements _Event {
  const _RemoveSelectedItems();

  @override
  String toString() => _$toString();
}

/// Update collection sort due to external changes
@toString
class _UpdateCollectionSort implements _Event {
  const _UpdateCollectionSort(this.sort);

  @override
  String toString() => _$toString();

  final collection_util.CollectionSort sort;
}

@toString
class _SetCollectionSort implements _Event {
  const _SetCollectionSort(this.sort);

  @override
  String toString() => _$toString();

  final collection_util.CollectionSort sort;
}
