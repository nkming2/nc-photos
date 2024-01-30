part of '../home_photos2.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc(
    this._c, {
    required this.account,
    required this.controller,
    required this.prefController,
    required this.accountPrefController,
    required this.collectionsController,
    required this.sessionController,
    required this.syncController,
    required this.personsController,
  }) : super(_State.init(
          zoom: prefController.homePhotosZoomLevel.value,
          isEnableMemoryCollection:
              accountPrefController.isEnableMemoryAlbum.value,
        )) {
    on<_LoadItems>(_onLoad);
    on<_Reload>(_onReload);
    on<_TransformItems>(_onTransformItems);
    on<_OnItemTransformed>(_onOnItemTransformed);

    on<_SetSelectedItems>(_onSetSelectedItems);
    on<_AddSelectedItemsToCollection>(_onAddSelectedItemsToCollection);
    on<_ArchiveSelectedItems>(_onArchiveSelectedItems);
    on<_DeleteSelectedItems>(_onDeleteSelectedItems);
    on<_DownloadSelectedItems>(_onDownloadSelectedItems);

    on<_AddVisibleItem>(_onAddVisibleItem);
    on<_RemoveVisibleItem>(_onRemoveVisibleItem);

    on<_SetContentListMaxExtent>(_onSetContentListMaxExtent);
    on<_SetSyncProgress>(_onSetSyncProgress);

    on<_StartScaling>(_onStartScaling);
    on<_EndScaling>(_onEndScaling);
    on<_SetScale>(_onSetScale);

    on<_SetEnableMemoryCollection>(_onSetEnableMemoryCollection);
    on<_SetSortByName>(_onSetSortByName);
    on<_SetMemoriesRange>(_onSetMemoriesRange);
    on<_SetEnableExif>(_onSetEnableExif);
    on<_UpdateDateTimeGroup>(_onUpdateDateTimeGroup);

    on<_SetError>(_onSetError);

    _subscriptions
        .add(accountPrefController.isEnableMemoryAlbum.listen((event) {
      add(_SetEnableMemoryCollection(event));
    }));
    _subscriptions.add(prefController.isPhotosTabSortByName.listen((event) {
      add(_SetSortByName(event));
    }));
    _subscriptions.add(prefController.memoriesRange.listen((event) {
      add(_SetMemoriesRange(event));
    }));
    _subscriptions.add(prefController.isEnableExif.listen((event) {
      add(_SetEnableExif(event));
    }));
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }

  @override
  String get tag => _log.fullName;

  @override
  bool Function(dynamic, dynamic)? get shouldLog => (currentState, nextState) {
        currentState = currentState as _State;
        nextState = nextState as _State;
        return currentState.scale == nextState.scale &&
            currentState.visibleItems == nextState.visibleItems &&
            currentState.syncProgress == nextState.syncProgress;
      };

  @override
  void onError(Object error, StackTrace stackTrace) {
    // we need this to prevent onError being triggered recursively
    if (!isClosed && !_isHandlingError) {
      _isHandlingError = true;
      try {
        add(_SetError(error, stackTrace));
      } catch (_) {}
      _isHandlingError = false;
    }
    super.onError(error, stackTrace);
  }

  Future<void> _onLoad(_LoadItems ev, Emitter<_State> emit) {
    _log.info(ev);
    return emit.forEach<FilesStreamEvent>(
      controller.stream,
      onData: (data) {
        if (_isInitialLoad && !data.hasNext) {
          _isInitialLoad = false;
          _syncRemote();
        }
        return state.copyWith(
          files: data.data,
          isLoading: data.hasNext || _itemTransformerQueue.isProcessing,
        );
      },
      onError: (e, stackTrace) {
        _log.severe("[_onLoad] Uncaught exception", e, stackTrace);
        return state.copyWith(
          isLoading: _itemTransformerQueue.isProcessing,
          error: ExceptionEvent(e, stackTrace),
        );
      },
    );
  }

  void _onReload(_Reload ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(syncProgress: const Progress(0)));
    _syncRemote();
  }

  void _onTransformItems(_TransformItems ev, Emitter<_State> emit) {
    _log.info(ev);
    _transformItems(ev.items);
    emit(state.copyWith(isLoading: true));
  }

  void _onOnItemTransformed(_OnItemTransformed ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(
      transformedItems: ev.items,
      memoryCollections: ev.memoryCollections,
      isLoading: _itemTransformerQueue.isProcessing,
    ));
    syncController.requestSync(
      account: account,
      filesController: controller,
      personsController: personsController,
      personProvider: accountPrefController.personProvider.value,
    );
    _tryStartMetadataTask();
  }

  void _onSetSelectedItems(_SetSelectedItems ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(selectedItems: ev.items));
  }

  void _onAddSelectedItemsToCollection(
      _AddSelectedItemsToCollection ev, Emitter<_State> emit) {
    _log.info(ev);
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFiles =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFiles.isNotEmpty) {
      final targetController = collectionsController.stream.value
          .itemsControllerByCollection(ev.collection);
      targetController.addFiles(selectedFiles).onError((e, stackTrace) {
        if (e != null) {
          add(_SetError(e, stackTrace));
        }
      });
    }
  }

  void _onArchiveSelectedItems(_ArchiveSelectedItems ev, Emitter<_State> emit) {
    _log.info(ev);
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFiles =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFiles.isNotEmpty) {
      controller.updateProperty(
        selectedFiles,
        isArchived: const OrNull(true),
        errorBuilder: (fileIds) => _ArchiveFailedError(fileIds.length),
      );
    }
  }

  void _onDeleteSelectedItems(_DeleteSelectedItems ev, Emitter<_State> emit) {
    _log.info(ev);
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFiles =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFiles.isNotEmpty) {
      controller.remove(
        selectedFiles,
        errorBuilder: (fileIds) => _RemoveFailedError(fileIds.length),
      );
    }
  }

  void _onDownloadSelectedItems(
      _DownloadSelectedItems ev, Emitter<_State> emit) {
    _log.info(ev);
    final selected = state.selectedItems;
    _clearSelection(emit);
    final selectedFiles =
        selected.whereType<_FileItem>().map((e) => e.file).toList();
    if (selectedFiles.isNotEmpty) {
      unawaited(DownloadHandler(_c).downloadFiles(account, selectedFiles));
    }
  }

  void _onAddVisibleItem(_AddVisibleItem ev, Emitter<_State> emit) {
    // _log.info(ev);
    if (state.visibleItems.contains(ev.item)) {
      return;
    }
    emit(state.copyWith(
      visibleItems: state.visibleItems.added(ev.item),
    ));
  }

  void _onRemoveVisibleItem(_RemoveVisibleItem ev, Emitter<_State> emit) {
    // _log.info(ev);
    if (!state.visibleItems.contains(ev.item)) {
      return;
    }
    emit(state.copyWith(
      visibleItems: state.visibleItems.removed(ev.item),
    ));
  }

  void _onSetContentListMaxExtent(
      _SetContentListMaxExtent ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(contentListMaxExtent: ev.value));
  }

  void _onSetSyncProgress(_SetSyncProgress ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(syncProgress: ev.progress));
  }

  void _onStartScaling(_StartScaling ev, Emitter<_State> emit) {
    _log.info(ev);
  }

  void _onEndScaling(_EndScaling ev, Emitter<_State> emit) {
    _log.info(ev);
    if (state.scale == null) {
      return;
    }
    final int newZoom;
    final currZoom = state.zoom;
    if (state.scale! >= 1.25) {
      // scale up
      newZoom = (currZoom + 1).clamp(-1, 2);
    } else if (state.scale! <= 0.75) {
      newZoom = (currZoom - 1).clamp(-1, 2);
    } else {
      newZoom = currZoom;
    }
    emit(state.copyWith(
      zoom: newZoom,
      scale: null,
    ));
    if ((currZoom >= 0) != (newZoom >= 0)) {
      add(const _UpdateDateTimeGroup());
    }
    unawaited(prefController.setHomePhotosZoomLevel(newZoom));
  }

  void _onSetScale(_SetScale ev, Emitter<_State> emit) {
    // _log.info(ev);
    emit(state.copyWith(scale: ev.scale));
  }

  void _onSetEnableMemoryCollection(
      _SetEnableMemoryCollection ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(isEnableMemoryCollection: ev.value));
  }

  void _onSetSortByName(_SetSortByName ev, Emitter<_State> emit) {
    _log.info(ev);
    _transformItems(state.files);
  }

  void _onSetMemoriesRange(_SetMemoriesRange ev, Emitter<_State> emit) {
    _log.info(ev);
    _transformItems(state.files);
  }

  void _onSetEnableExif(_SetEnableExif ev, Emitter<_State> emit) {
    _log.info(ev);
    if (ev.value) {
      _tryStartMetadataTask(ignoreFired: true);
    } else {
      _stopMetadataTask();
    }
  }

  void _onUpdateDateTimeGroup(_UpdateDateTimeGroup ev, Emitter<_State> emit) {
    _log.info(ev);
    _transformItems(state.files);
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  Future _transformItems(List<FileDescriptor> files) async {
    _log.info("[_transformItems] Queue ${files.length} items");
    _itemTransformerQueue.addJob(
      _ItemTransformerArgument(
        account: account,
        files: files,
        sort: prefController.isPhotosTabSortByName.value
            ? _ItemSort.filename
            : _ItemSort.dateTime,
        isGroupByDay: prefController.homePhotosZoomLevel.value >= 0,
        memoriesDayRange: prefController.memoriesRange.value,
        locale: language_util.getSelectedLocale() ??
            PlatformDispatcher.instance.locale,
      ),
      _buildItem,
      (result) {
        if (!isClosed) {
          add(_OnItemTransformed(result.items, result.memoryCollections));
        }
      },
    );
  }

  void _syncRemote() {
    final stopwatch = Stopwatch()..start();
    controller.syncRemote(
      onProgressUpdate: (progress) {
        if (!isClosed) {
          add(_SetSyncProgress(progress));
        }
      },
    ).whenComplete(() {
      if (!isClosed) {
        add(const _SetSyncProgress(null));
      }
      _log.info(
          "[_syncRemote] Elapsed time: ${stopwatch.elapsedMilliseconds}ms");
    });
  }

  void _clearSelection(Emitter<_State> emit) {
    emit(state.copyWith(selectedItems: const {}));
  }

  Future<void> _tryStartMetadataTask({
    bool ignoreFired = false,
  }) async {
    if (state.files.isNotEmpty &&
        prefController.isEnableExif.value &&
        (ignoreFired || !sessionController.hasFiredMetadataTask.value)) {
      sessionController.setFiredMetadataTask(true);
      try {
        final missingMetadataCount =
            await _c.npDb.countFilesByFileIdsMissingMetadata(
          account: account.toDb(),
          fileIds: state.files.map((e) => e.fdId).toList(),
          mimes: file_util.supportedImageFormatMimes,
        );
        _log.info(
            "[_tryStartMetadataTask] Missing count: $missingMetadataCount");
        if (missingMetadataCount > 0) {
          unawaited(service.startService());
        }
      } catch (e, stackTrace) {
        _log.shout("[_tryStartMetadataTask] Failed starting metadata task", e,
            stackTrace);
      }
    }
  }

  void _stopMetadataTask() {
    service.stopService();
  }

  final DiContainer _c;
  final Account account;
  final FilesController controller;
  final PrefController prefController;
  final AccountPrefController accountPrefController;
  final CollectionsController collectionsController;
  final SessionController sessionController;
  final SyncController syncController;
  final PersonsController personsController;

  final _itemTransformerQueue =
      ComputeQueue<_ItemTransformerArgument, _ItemTransformerResult>();
  final _subscriptions = <StreamSubscription>[];
  var _isHandlingError = false;
  var _isInitialLoad = true;
}

_ItemTransformerResult _buildItem(_ItemTransformerArgument arg) {
  final int Function(FileDescriptor, FileDescriptor) sorter;
  switch (arg.sort) {
    case _ItemSort.filename:
      sorter = (a, b) => a.fdPath.compareTo(b.fdPath);
      break;
    case _ItemSort.dateTime:
    default:
      sorter = compareFileDescriptorDateTimeDescending;
      break;
  }

  final sortedFiles =
      arg.files.where((f) => f.fdIsArchived != true).sorted(sorter);
  final dateHelper = arg.sort == _ItemSort.dateTime
      ? photo_list_util.DateGroupHelper(isMonthOnly: !arg.isGroupByDay)
      : null;
  final today = clock.now();
  final memoryCollectionHelper = arg.sort == _ItemSort.dateTime
      ? photo_list_util.MemoryCollectionHelper(
          arg.account,
          today: today,
          dayRange: arg.memoriesDayRange,
        )
      : null;

  final transformed = <_Item>[];
  for (int i = 0; i < sortedFiles.length; ++i) {
    final file = sortedFiles[i];
    final item = _buildSingleItem(arg.account, file);
    if (item == null) {
      continue;
    }
    final date = dateHelper?.onFile(file);
    if (date != null) {
      transformed.add(_DateItem(date: date, isMonthOnly: !arg.isGroupByDay));
    }
    transformed.add(item);
    memoryCollectionHelper?.addFile(file);
  }
  final memoryCollections = memoryCollectionHelper
      ?.build((year) => L10n.of(arg.locale).memoryAlbumName(today.year - year));
  return _ItemTransformerResult(
    items: transformed,
    memoryCollections: memoryCollections ?? [],
  );
}

_Item? _buildSingleItem(Account account, FileDescriptor file) {
  if (file_util.isSupportedImageFormat(file)) {
    return _PhotoItem(
      file: file,
      account: account,
    );
  } else if (file_util.isSupportedVideoFormat(file)) {
    return _VideoItem(
      file: file,
      account: account,
    );
  } else {
    _$__NpLog.log
        .shout("[_buildSingleItem] Unsupported file format: ${file.fdMime}");
    return null;
  }
}
