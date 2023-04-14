part of '../collection_browser.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> implements BlocTag {
  _Bloc({
    required DiContainer container,
    required this.account,
    required this.collectionsController,
    required Collection collection,
  })  : _c = container,
        super(_State.init(
          collection: collection,
          coverUrl: _getCoverUrl(collection),
        )) {
    _initItemController(collection);

    on<_UpdateCollection>(_onUpdateCollection);
    on<_LoadItems>(_onLoad);
    on<_TransformItems>(_onTransformItems);

    on<_BeginEdit>(_onBeginEdit);
    on<_EditName>(_onEditName);
    on<_AddLabelToCollection>(_onAddLabelToCollection);
    on<_EditSort>(_onEditSort);
    on<_EditManualSort>(_onEditManualSort);
    on<_TransformEditItems>(_onTransformEditItems);
    on<_DoneEdit>(_onDoneEdit, transformer: concurrent());
    on<_CancelEdit>(_onCancelEdit);

    on<_SetSelectedItems>(_onSetSelectedItems);
    on<_DownloadSelectedItems>(_onDownloadSelectedItems);
    on<_AddSelectedItemsToCollection>(_onAddSelectedItemsToCollection);
    on<_RemoveSelectedItemsFromCollection>(
        _onRemoveSelectedItemsFromCollection);
    on<_ArchiveSelectedItems>(_onArchiveSelectedItems,
        transformer: concurrent());
    on<_DeleteSelectedItems>(_onDeleteSelectedItems);

    on<_SetDragging>(_onSetDragging);

    on<_SetError>(_onSetError);
    on<_SetMessage>(_onSetMessage);

    _collectionControllerSubscription =
        collectionsController.stream.listen((event) {
      final c = event.data
          .firstWhere((d) => state.collection.compareIdentity(d.collection));
      if (!identical(c, state.collection)) {
        add(_UpdateCollection(c.collection));
      }
    });
    _itemsControllerSubscription = itemsController.stream.listen(
      (_) {},
      onError: (e, stackTrace) {
        add(_SetError(e, stackTrace));
      },
    );
  }

  @override
  Future<void> close() {
    _collectionControllerSubscription?.cancel();
    _itemsControllerSubscription?.cancel();
    return super.close();
  }

  @override
  String get tag => _log.fullName;

  void _onUpdateCollection(_UpdateCollection ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(collection: ev.collection));
  }

  Future<void> _onLoad(_LoadItems ev, Emitter<_State> emit) {
    _log.info("$ev");
    return emit.forEach<CollectionItemStreamData>(
      itemsController.stream.handleError((e, stackTrace) {
        _log.severe("[_onLoad] Uncaught exception", e, stackTrace);
        return state.copyWith(
          isLoading: false,
          error: ExceptionEvent(e, stackTrace),
        );
      }),
      onData: (data) => state.copyWith(
        items: data.items,
        isLoading: data.hasNext,
      ),
    );
  }

  void _onTransformItems(_TransformItems ev, Emitter<_State> emit) {
    _log.info("$ev");
    final result = _transformItems(ev.items, state.collection.itemSort);
    var newState = state.copyWith(transformedItems: result.transformed);
    if (state.coverUrl == null) {
      // if cover is not managed by the collection, use the first item
      final cover = _getCoverUrlOnNewItem(result.sorted);
      if (cover != null) {
        newState = newState.copyWith(coverUrl: cover);
      }
    }
    emit(newState);
  }

  void _onBeginEdit(_BeginEdit ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(isEditMode: true));
  }

  void _onEditName(_EditName ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(editName: ev.name));
  }

  void _onAddLabelToCollection(_AddLabelToCollection ev, Emitter<_State> emit) {
    _log.info("$ev");
    assert(
        state.collection.capabilities.contains(CollectionCapability.labelItem));
    emit(state.copyWith(
      editItems: [
        NewCollectionLabelItem(ev.label, clock.now().toUtc()),
        ...state.editItems ?? state.items,
      ],
    ));
  }

  void _onEditSort(_EditSort ev, Emitter<_State> emit) {
    _log.info("$ev");
    final result = _transformItems(state.editItems ?? state.items, ev.sort);
    emit(state.copyWith(
      editSort: ev.sort,
      editTransformedItems: result.transformed,
    ));
  }

  void _onEditManualSort(_EditManualSort ev, Emitter<_State> emit) {
    _log.info("$ev");
    assert(state.collection.capabilities
        .contains(CollectionCapability.manualSort));
    emit(state.copyWith(
      editSort: CollectionItemSort.manual,
      editItems:
          ev.sorted.whereType<_ActualItem>().map((e) => e.original).toList(),
      editTransformedItems: ev.sorted,
    ));
  }

  void _onTransformEditItems(_TransformEditItems ev, Emitter<_State> emit) {
    _log.info("$ev");
    final result =
        _transformItems(ev.items, state.editSort ?? state.collection.itemSort);
    emit(state.copyWith(editTransformedItems: result.transformed));
  }

  Future<void> _onDoneEdit(_DoneEdit ev, Emitter<_State> emit) async {
    _log.info("$ev");
    emit(state.copyWith(isEditBusy: true));
    try {
      await collectionsController.edit(
        state.collection,
        name: state.editName,
        items: state.editItems,
        itemSort: state.editSort,
      );
      emit(state.copyWith(
        isEditMode: false,
        isEditBusy: false,
        editName: null,
        editItems: null,
        editTransformedItems: null,
        editSort: null,
      ));
    } catch (e, stackTrace) {
      _log.severe("[_onDoneEdit] Failed while edit", e, stackTrace);
      emit(state.copyWith(
        error: ExceptionEvent(e, stackTrace),
        isEditBusy: false,
      ));
    }
  }

  void _onCancelEdit(_CancelEdit ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(
      isEditMode: false,
      editName: null,
      editItems: null,
      editTransformedItems: null,
      editSort: null,
    ));
  }

  void _onSetSelectedItems(_SetSelectedItems ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(
      selectedItems: ev.items,
      isSelectionRemovable: CollectionAdapter.of(_c, account, state.collection)
          .isItemsRemovable(ev.items
              .whereType<_ActualItem>()
              .map((e) => e.original)
              .toList()),
    ));
  }

  void _onDownloadSelectedItems(
      _DownloadSelectedItems ev, Emitter<_State> emit) {
    _log.info("$ev");
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFiles =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFiles.isNotEmpty) {
      unawaited(DownloadHandler(_c).downloadFiles(account, selectedFiles));
    }
  }

  void _onAddSelectedItemsToCollection(
      _AddSelectedItemsToCollection ev, Emitter<_State> emit) {
    _log.info("$ev");
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFiles =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFiles.isNotEmpty) {
      final targetController = collectionsController.stream.value
          .itemsControllerByCollection(ev.collection);
      unawaited(targetController.addFiles(selectedFiles));
    }
  }

  void _onRemoveSelectedItemsFromCollection(
      _RemoveSelectedItemsFromCollection ev, Emitter<_State> emit) {
    _log.info("$ev");
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedItems =
        selected.whereType<_ActualItem>().map((e) => e.original).toList();
    if (selectedItems.isNotEmpty) {
      unawaited(itemsController.removeItems(selectedItems));
    }
  }

  Future<void> _onArchiveSelectedItems(
      _ArchiveSelectedItems ev, Emitter<_State> emit) async {
    _log.info("$ev");
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFds =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFds.isNotEmpty) {
      final selectedFiles =
          await InflateFileDescriptor(_c)(account, selectedFds);
      final count = await ArchiveFile(_c)(account, selectedFiles);
      if (count != selectedFiles.length) {
        emit(state.copyWith(
          message: L10n.global()
              .archiveSelectedFailureNotification(selectedFiles.length - count),
        ));
      }
    }
  }

  Future<void> _onDeleteSelectedItems(
      _DeleteSelectedItems ev, Emitter<_State> emit) async {
    _log.info("$ev");
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFiles =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFiles.isNotEmpty) {
      final count = await Remove(_c)(
        account,
        selectedFiles,
        onError: (_, f, e, stackTrace) {
          _log.severe(
            "[_onDeleteSelectedItems] Failed while Remove: ${logFilename(f.strippedPath)}",
            e,
            stackTrace,
          );
        },
      );
      if (count != selectedFiles.length) {
        emit(state.copyWith(
          message: L10n.global()
              .deleteSelectedFailureNotification(selectedFiles.length - count),
        ));
      }
    }
  }

  void _onSetDragging(_SetDragging ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(isDragging: ev.flag));
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  void _onSetMessage(_SetMessage ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(message: ev.message));
  }

  void _initItemController(Collection collection) {
    try {
      itemsController = collectionsController.stream.value
          .itemsControllerByCollection(collection);
    } catch (e) {
      _log.info(
        "[_initItemController] Collection not found in global controller, building new ad-hoc item controller",
        e,
      );
      itemsController = CollectionItemsController(
        _c,
        account: account,
        collection: collection,
        onCollectionUpdated: (_) {},
      );
    }
  }

  void _clearSelection(Emitter<_State> emit) {
    emit(state.copyWith(
      selectedItems: const {},
      isSelectionRemovable: true,
      isSelectionManageableFile: true,
    ));
  }

  /// Convert [CollectionItem] to the corresponding [_Item]
  _TransformResult _transformItems(
      List<CollectionItem> items, CollectionItemSort sort) {
    final sorter = CollectionSorter.fromSortType(sort);
    final sortedItems = sorter(items);
    final dateHelper = photo_list_util.DateGroupHelper(isMonthOnly: false);

    final transformed = <_Item>[];
    for (int i = 0; i < sortedItems.length; ++i) {
      final item = sortedItems[i];
      if (item is CollectionFileItem) {
        if (sorter is CollectionTimeSorter &&
            _c.pref.isAlbumBrowserShowDateOr()) {
          final date = dateHelper.onFile(item.file);
          if (date != null) {
            transformed.add(_DateItem(date: date));
          }
        }

        if (file_util.isSupportedImageMime(item.file.fdMime ?? "")) {
          transformed.add(_PhotoItem(
            original: item,
            file: item.file,
            account: account,
          ));
        } else if (file_util.isSupportedVideoMime(item.file.fdMime ?? "")) {
          transformed.add(_VideoItem(
            original: item,
            file: item.file,
            account: account,
          ));
        } else {
          _log.shout(
              "[_transformItems] Unsupported file format: ${item.file.fdMime}");
        }
      } else if (item is CollectionLabelItem) {
        if (state.isEditMode) {
          transformed.add(_EditLabelListItem(
            original: item,
            id: item.id,
            text: item.text,
            onEditPressed: () {
              // TODO
            },
          ));
        } else {
          transformed.add(_LabelItem(
            original: item,
            id: item.id,
            text: item.text,
          ));
        }
      }
    }
    return _TransformResult(
      sorted: sortedItems,
      transformed: transformed,
    );
  }

  String? _getCoverUrlOnNewItem(List<CollectionItem> sortedItems) {
    try {
      final firstFile =
          (sortedItems.firstWhereOrNull((i) => i is CollectionFileItem)
                  as CollectionFileItem?)
              ?.file;
      if (firstFile != null) {
        return api_util.getFilePreviewUrlByFileId(
          account,
          firstFile.fdId,
          width: k.coverSize,
          height: k.coverSize,
          isKeepAspectRatio: false,
        );
      }
    } catch (_) {}
    return null;
  }

  static String? _getCoverUrl(Collection collection) {
    try {
      return collection.contentProvider.getCoverUrl(k.coverSize, k.coverSize);
    } catch (_) {
      return null;
    }
  }

  final DiContainer _c;
  final Account account;
  final CollectionsController collectionsController;
  late final CollectionItemsController itemsController;

  StreamSubscription? _collectionControllerSubscription;
  StreamSubscription? _itemsControllerSubscription;
}

class _TransformResult {
  const _TransformResult({
    required this.sorted,
    required this.transformed,
  });

  final List<CollectionItem> sorted;
  final List<_Item> transformed;
}
