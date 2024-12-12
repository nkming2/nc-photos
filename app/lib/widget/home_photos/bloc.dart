part of '../home_photos2.dart';

@npLog
class _Bloc extends Bloc<_Event, _State>
    with BlocLogger, BlocForEachMixin<_Event, _State> {
  _Bloc(
    this._c, {
    required this.account,
    required this.filesController,
    required this.prefController,
    required this.accountPrefController,
    required this.collectionsController,
    required this.syncController,
    required this.personsController,
    required this.metadataController,
    required this.serverController,
  }) : super(_State.init(
          zoom: prefController.homePhotosZoomLevelValue,
          isEnableMemoryCollection:
              accountPrefController.isEnableMemoryAlbumValue,
        )) {
    on<_LoadItems>(_onLoad);
    on<_RequestRefresh>(_onRequestRefresh);
    on<_TransformItems>(_onTransformItems);
    on<_OnItemTransformed>(_onOnItemTransformed);

    on<_SetSelectedItems>(_onSetSelectedItems);
    on<_AddSelectedItemsToCollection>(_onAddSelectedItemsToCollection);
    on<_ArchiveSelectedItems>(_onArchiveSelectedItems);
    on<_DeleteSelectedItems>(_onDeleteSelectedItems);
    on<_DownloadSelectedItems>(_onDownloadSelectedItems);

    on<_AddVisibleDate>(_onAddVisibleDate);
    on<_RemoveVisibleDate>(_onRemoveVisibleDate);

    on<_SetContentListMaxExtent>(_onSetContentListMaxExtent);
    on<_SetSyncProgress>(_onSetSyncProgress);

    on<_StartScaling>(_onStartScaling);
    on<_EndScaling>(_onEndScaling);
    on<_SetScale>(_onSetScale);

    on<_StartScrolling>(_onStartScrolling);
    on<_EndScrolling>(_onEndScrolling);
    on<_SetLayoutConstraint>(_onSetLayoutConstraint);
    on<_TransformMinimap>(_onTransformMinimap);
    on<_UpdateScrollDate>(_onUpdateScrollDate);

    on<_SetEnableMemoryCollection>(_onSetEnableMemoryCollection);
    on<_UpdateDateTimeGroup>(_onUpdateDateTimeGroup);
    on<_UpdateMemories>(_onUpdateMemories);

    on<_TripMissingVideoPreview>(_onTripMissingVideoPreview);

    on<_UpdateBannerAdExtent>(_onUpdateBannerAdExtent);

    on<_SetError>(_onSetError);

    _subscriptions
        .add(accountPrefController.isEnableMemoryAlbumChange.listen((event) {
      add(_SetEnableMemoryCollection(event));
    }));
    _subscriptions.add(stream
        .distinct((previous, next) =>
            previous.filesSummary == next.filesSummary &&
            previous.viewHeight == next.viewHeight &&
            previous.itemPerRow == next.itemPerRow &&
            previous.itemSize == next.itemSize)
        .listen((event) {
      add(const _TransformMinimap());
    }));
    _subscriptions.add(stream
        .distinct((previous, next) =>
            previous.filesSummary == next.filesSummary &&
            previous.files == next.files)
        .listen((event) {
      add(_TransformItems(event.files, event.filesSummary));
    }));
    _subscriptions.add(stream
        .distinctBy(
            (e) => e.visibleDates.map((d) => d.date).sortedBySelf().lastOrNull)
        .listen((event) {
      _onVisibleDatesUpdated();
    }));
    _subscriptions.add(stream
        .distinct(
      (previous, next) =>
          previous.visibleDates == next.visibleDates &&
          previous.itemPerRow == next.itemPerRow,
    )
        .listen((event) {
      add(const _UpdateScrollDate());
    }));
    _subscriptions.add(stream
        .distinct(
            (previous, next) => previous.filesSummary == next.filesSummary)
        .listen((_) {
      add(const _UpdateMemories());
    }));
    _subscriptions.add(prefController.memoriesRangeChange.listen((_) {
      add(const _UpdateMemories());
    }));
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _filesQueryTimer?.cancel();
    return super.close();
  }

  @override
  String get tag => _log.fullName;

  @override
  bool Function(dynamic, dynamic)? get shouldLog => (currentState, nextState) {
        currentState = currentState as _State;
        nextState = nextState as _State;
        return currentState.scale == nextState.scale &&
            currentState.visibleDates == nextState.visibleDates &&
            currentState.syncProgress == nextState.syncProgress &&
            currentState.scrollDate == nextState.scrollDate;
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

  Future<void> _onLoad(_LoadItems ev, Emitter<_State> emit) async {
    _log.info(ev);
    await Future.wait([
      forEach(
        emit,
        filesController.summaryStream,
        onData: (data) {
          if (data.summary.items.isEmpty && _isInitialLoad) {
            // no data, initial sync
            _isInitialLoad = false;
            _syncRemote();
          }
          return state.copyWith(
            filesSummary: data.summary,
          );
        },
        onError: (e, stackTrace) {
          _log.severe("[_onLoad] Uncaught exception", e, stackTrace);
          return state.copyWith(
            error: ExceptionEvent(e, stackTrace),
          );
        },
      ),
      forEach(
        emit,
        filesController.timelineStream,
        onData: (data) {
          if (!data.isDummy && _isInitialLoad) {
            _isInitialLoad = false;
            _syncRemote();
          }
          return state.copyWith(
            files: data.data.values.toList(),
          );
        },
        onError: (e, stackTrace) {
          _log.severe("[_onLoad] Uncaught exception", e, stackTrace);
          return state.copyWith(
            error: ExceptionEvent(e, stackTrace),
          );
        },
      ),
    ]);
  }

  void _onRequestRefresh(_RequestRefresh ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(syncProgress: const Progress(0)));
    _syncRemote();
    metadataController.scheduleNext();
  }

  void _onTransformItems(_TransformItems ev, Emitter<_State> emit) {
    _log.info(ev);
    _transformItems(ev.files, ev.summary);
    emit(state.copyWith(isLoading: true));
  }

  void _onOnItemTransformed(_OnItemTransformed ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(
      transformedItems: ev.items,
      isLoading: _itemTransformerQueue.isProcessing,
      queriedDates: ev.dates,
    ));
    _requestMoreFiles(ev.dates);
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
      filesController.updateProperty(
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
      filesController.remove(
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

  void _onAddVisibleDate(_AddVisibleDate ev, Emitter<_State> emit) {
    // _log.info(ev);
    if (state.visibleDates.contains(ev.date)) {
      return;
    }
    emit(state.copyWith(visibleDates: state.visibleDates.added(ev.date)));
  }

  void _onRemoveVisibleDate(_RemoveVisibleDate ev, Emitter<_State> emit) {
    // _log.info(ev);
    if (!state.visibleDates.contains(ev.date)) {
      return;
    }
    emit(state.copyWith(visibleDates: state.visibleDates.removed(ev.date)));
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

  Future<void> _onEndScaling(_EndScaling ev, Emitter<_State> emit) async {
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
    await prefController.setHomePhotosZoomLevel(newZoom);
    if ((currZoom >= 0) != (newZoom >= 0)) {
      add(const _UpdateDateTimeGroup());
    }
  }

  void _onStartScrolling(_StartScrolling ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(isScrolling: true));
  }

  void _onEndScrolling(_EndScrolling ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(isScrolling: false));
  }

  void _onSetScale(_SetScale ev, Emitter<_State> emit) {
    // _log.info(ev);
    emit(state.copyWith(scale: ev.scale));
  }

  void _onSetLayoutConstraint(_SetLayoutConstraint ev, Emitter<_State> emit) {
    _log.info(ev);
    if (state.viewHeight == ev.viewHeight && state.viewWidth == ev.viewWidth) {
      // nothing changed
      return;
    }
    final measurement = _measureItem(
        ev.viewWidth, photo_list_util.getThumbSize(state.zoom).toDouble());
    emit(state.copyWith(
      viewWidth: ev.viewWidth,
      viewHeight: ev.viewHeight,
      itemPerRow: measurement.itemPerRow,
      itemSize: measurement.itemSize,
    ));
  }

  Future<void> _onTransformMinimap(
      _TransformMinimap ev, Emitter<_State> emit) async {
    _log.info(ev);
    if (state.itemSize == null ||
        state.itemPerRow == null ||
        state.viewHeight == null) {
      _log.warning("[_onTransformMinimap] Layout measurements not ready");
      return;
    }
    final maker = prefController.homePhotosZoomLevelValue >= 0
        ? _makeMinimapItems
        : _makeMonthGroupMinimapItems;
    final minimapItems = maker(
      filesSummary: state.filesSummary,
      itemSize: state.itemSize!,
      itemPerRow: state.itemPerRow!,
      viewHeight: state.viewHeight!,
    );
    final totalHeight = (state.bannerAdExtent ?? 0) +
        minimapItems.map((e) => e.logicalHeight).sum;
    final ratio = state.viewHeight! / totalHeight;
    _log.info(
        "[_onTransformMinimap] view height: ${state.viewHeight!}, logical height: $totalHeight");
    emit(state.copyWith(
      minimapItems: minimapItems,
      minimapYRatio: ratio,
    ));
  }

  void _onUpdateScrollDate(_UpdateScrollDate ev, Emitter<_State> emit) {
    // _log.info(ev);
    if (state.itemPerRow == null || state.visibleDates.isEmpty) {
      if (state.scrollDate != null) {
        emit(state.copyWith(scrollDate: null));
      }
      return;
    }
    final dateRows = state.visibleDates
        .map((e) => e.date)
        .sortedBySelf()
        .reversed
        .groupBy(key: (e) {
      if (prefController.homePhotosZoomLevelValue >= 0) {
        return e;
      } else {
        // month
        return Date(e.year, e.month);
      }
    }).map((key, value) =>
            MapEntry(key, (value.length / state.itemPerRow!).ceil()));
    final totalRows = dateRows.values.sum;
    final midRow = totalRows / 2;
    var x = 0;
    for (final e in dateRows.entries) {
      x += e.value;
      if (x >= midRow) {
        if (state.scrollDate != e.key) {
          emit(state.copyWith(scrollDate: e.key));
        }
        return;
      }
    }
  }

  void _onSetEnableMemoryCollection(
      _SetEnableMemoryCollection ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(isEnableMemoryCollection: ev.value));
    if (ev.value) {
      add(const _UpdateMemories());
    }
  }

  void _onUpdateDateTimeGroup(_UpdateDateTimeGroup ev, Emitter<_State> emit) {
    _log.info(ev);
    if (state.viewWidth != null) {
      final measurement = _measureItem(state.viewWidth!,
          photo_list_util.getThumbSize(state.zoom).toDouble());
      emit(state.copyWith(
        itemPerRow: measurement.itemPerRow,
        itemSize: measurement.itemSize,
      ));
    }
    _transformItems(state.files, state.filesSummary);
    add(const _TransformMinimap());
  }

  Future<void> _onUpdateMemories(
      _UpdateMemories ev, Emitter<_State> emit) async {
    _log.info(ev);
    final localToday = clock.now().toLocal().toDate();
    final dbMemories = await _c.npDb.getFilesMemories(
      account: account.toDb(),
      at: localToday,
      radius: prefController.memoriesRangeValue,
      includeRelativeRoots: account.roots
          .map((e) => File(path: file_util.unstripPath(account, e))
              .strippedPathWithEmpty)
          .toList(),
      excludeRelativeRoots: [remote_storage_util.remoteStorageDirRelativePath],
      mimes: file_util.supportedFormatMimes,
    );
    emit(state.copyWith(
      memoryCollections: dbMemories.memories.entries
          .sorted((a, b) => a.key.compareTo(b.key))
          .reversed
          .map((e) {
        final center = localToday
            .copyWith(year: e.key)
            .toLocalDateTime()
            .copyWith(hour: 12);
        return Collection(
          name: L10n.global().memoryAlbumName(localToday.year - e.key),
          contentProvider: CollectionMemoryProvider(
            account: account,
            year: e.key,
            month: localToday.month,
            day: localToday.day,
            cover: e.value
                .map((e) =>
                    (comparable: e.bestDateTime.difference(center), item: e))
                .sorted((a, b) => a.comparable.compareTo(b.comparable))
                .firstOrNull
                ?.let((e) => DbFileDescriptorConverter.fromDb(
                    account.userId.toString(), e.item)),
          ),
        );
      }).toList(),
    ));
  }

  void _onTripMissingVideoPreview(
      _TripMissingVideoPreview ev, Emitter<_State> emit) {
    // _log.info(ev);
    if (!state.hasMissingVideoPreview) {
      emit(state.copyWith(hasMissingVideoPreview: true));
    }
  }

  void _onUpdateBannerAdExtent(_UpdateBannerAdExtent ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(bannerAdExtent: ev.value));
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  Future _transformItems(
      List<FileDescriptor> files, DbFilesSummary? summary) async {
    _log.info("[_transformItems] Queue ${files.length} items");
    _itemTransformerQueue.addJob(
      _ItemTransformerArgument(
        account: account,
        files: files,
        summary: summary,
        itemPerRow: state.itemPerRow,
        itemSize: state.itemSize,
        isGroupByDay: prefController.homePhotosZoomLevelValue >= 0,
      ),
      _buildItem,
      (result) {
        if (!isClosed) {
          add(_OnItemTransformed(result.items, result.dates));
        }
      },
    );
  }

  void _syncRemote() {
    final stopwatch = Stopwatch()..start();
    filesController.syncRemote(
      onProgressUpdate: (progress) {
        if (!isClosed) {
          add(_SetSyncProgress(progress));
        }
      },
    ).whenComplete(() {
      if (!isClosed) {
        add(const _SetSyncProgress(null));
      }
      syncController.requestSync(
        account: account,
        filesController: filesController,
        personsController: personsController,
        personProvider: accountPrefController.personProviderValue,
      );
      metadataController.kickstart();
      _log.info(
          "[_syncRemote] Elapsed time: ${stopwatch.elapsedMilliseconds}ms");
    });
  }

  void _clearSelection(Emitter<_State> emit) {
    emit(state.copyWith(selectedItems: const {}));
  }

  void _onVisibleDatesUpdated() {
    _filesQueryTimer?.cancel();
    _filesQueryTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isQueryingFiles) {
        _requestMoreFiles();
      }
    });
  }

  void _requestMoreFiles([Set<Date>? queriedDates]) {
    queriedDates ??= state.queriedDates;
    final missingDates = state.visibleDates
        .map((e) => e.date)
        .whereNot((d) => queriedDates!.contains(d))
        .where((d) => state.filesSummary.items.containsKey(d))
        .toSet();
    if (missingDates.isNotEmpty) {
      _requestFilesFrom(missingDates.sortedBySelf().last);
    } else {
      _isQueryingFiles = false;
    }
  }

  /// Query a set number of files taken on or before [at]
  void _requestFilesFrom(Date at) {
    const targetFileCount = 100;

    _log.info("[_requestFilesFrom] $at");
    _isQueryingFiles = true;
    final summary = state.filesSummary;
    var dates = summary.items.keys.toList();
    final i = dates.indexWhere((e) => e.isBeforeOrAt(at));
    if (i == -1) {
      _log.info("[_requestFilesFrom] No more files before $at");
      return;
    }
    dates = dates.sublist(i);
    final begin = dates.first;
    _log.info("[_requestFilesFrom] First date of interest: $begin");
    var count = 0;
    Date? end;
    for (final d in dates) {
      count += summary.items[d]!.count;
      end = d;
      if (count >= targetFileCount) {
        break;
      }
    }
    _log.info("[_requestFilesFrom] Query $count files until $end");
    filesController
        .queryTimelineByDateRange(DateRange(from: end, to: at.add(day: 1)))
        .onError((e, stackTrace) {
      _isQueryingFiles = false;
    });
  }

  List<_MinimapItem> _makeMonthGroupMinimapItems({
    required DbFilesSummary filesSummary,
    required double itemSize,
    required int itemPerRow,
    required double viewHeight,
  }) {
    _log.info(
        "[_makeMonthGroupMinimapItems] itemSize: $itemSize, itemPerRow: $itemPerRow, viewHeight: $viewHeight");
    double position = 0;
    Date? currentMonth;
    double currentMonthY = 0;
    var currentMonthCount = 0;
    final results = <_MinimapItem>[];
    for (final e in filesSummary.items.entries) {
      final thisMonth = Date(e.key.year, e.key.month);
      if (currentMonth != thisMonth) {
        if (currentMonth != null) {
          final h = _getLogicalHeightByItemCount(
            itemCount: currentMonthCount,
            rowHeight: itemSize,
            itemPerRow: itemPerRow,
          );
          results.add(_MinimapItem(
            date: currentMonth,
            logicalY: currentMonthY,
            logicalHeight: h,
          ));
          position += h;
        }
        currentMonth = thisMonth;
        currentMonthY = position;
        currentMonthCount = e.value.count;
      } else {
        currentMonthCount += e.value.count;
      }
    }
    // add the last month
    if (currentMonth != null) {
      final h = _getLogicalHeightByItemCount(
        itemCount: currentMonthCount,
        rowHeight: itemSize,
        itemPerRow: itemPerRow,
      );
      results.add(_MinimapItem(
        date: currentMonth,
        logicalY: currentMonthY,
        // we need to take screen(view) height into account
        logicalHeight: h,
      ));
    }
    return results;
  }

  List<_MinimapItem> _makeMinimapItems({
    required DbFilesSummary filesSummary,
    required double itemSize,
    required int itemPerRow,
    required double viewHeight,
  }) {
    _log.info(
        "[_makeMinimapItems] itemSize: $itemSize, itemPerRow: $itemPerRow, viewHeight: $viewHeight");
    double position = 0;
    Date? currentMonth;
    double currentMonthY = 0;
    double currentMonthHeight = 0;
    final results = <_MinimapItem>[];
    for (final e in filesSummary.items.entries) {
      final thisMonth = Date(e.key.year, e.key.month);
      final h = _getLogicalHeightByItemCount(
        itemCount: e.value.count,
        rowHeight: itemSize,
        itemPerRow: itemPerRow,
      );
      if (currentMonth != thisMonth) {
        if (currentMonth != null) {
          results.add(_MinimapItem(
            date: currentMonth,
            logicalY: currentMonthY,
            logicalHeight: currentMonthHeight,
          ));
        }
        currentMonth = thisMonth;
        currentMonthY = position;
        currentMonthHeight = h;
      } else {
        currentMonthHeight += h;
      }
      position += h;
    }
    // add the last month
    if (currentMonth != null) {
      results.add(_MinimapItem(
        date: currentMonth,
        logicalY: currentMonthY,
        // we need to take screen(view) height into account
        logicalHeight: currentMonthHeight + viewHeight,
      ));
    }
    return results;
  }

  final DiContainer _c;
  final Account account;
  final FilesController filesController;
  final PrefController prefController;
  final AccountPrefController accountPrefController;
  final CollectionsController collectionsController;
  final SyncController syncController;
  final PersonsController personsController;
  final MetadataController metadataController;
  final ServerController serverController;

  final _itemTransformerQueue =
      ComputeQueue<_ItemTransformerArgument, _ItemTransformerResult>();
  final _subscriptions = <StreamSubscription>[];
  var _isHandlingError = false;
  var _isInitialLoad = true;
  var _isQueryingFiles = false;
  Timer? _filesQueryTimer;
}

double _getLogicalHeightByItemCount({
  required int itemCount,
  required double rowHeight,
  required int itemPerRow,
}) {
  const dateHeight = 32.0;
  return dateHeight + (itemCount / itemPerRow).ceil() * rowHeight;
}

_ItemTransformerResult _buildItem(_ItemTransformerArgument arg) {
  const int Function(FileDescriptor, FileDescriptor) sorter =
      compareFileDescriptorDateTimeDescending;

  final stopwatch = Stopwatch()..start();
  final sortedFiles =
      arg.files.where((f) => f.fdIsArchived != true).sorted(sorter);
  stopwatch.reset();

  final tzOffset = clock.now().timeZoneOffset;
  final fileGroups = groupBy<FileDescriptor, Date>(
    sortedFiles,
    (e) {
      // convert to local date
      return e.fdDateTime.add(tzOffset).toDate();
    },
  );
  stopwatch.reset();

  final dateHelper =
      photo_list_util.DateGroupHelper(isMonthOnly: !arg.isGroupByDay);
  final dateTimeSet = SplayTreeSet<Date>.of([
    ...fileGroups.keys,
    if (arg.summary != null) ...arg.summary!.items.keys,
  ], (key1, key2) => key2.compareTo(key1));
  final transformed = <_Item>[];
  final dates = <Date>{};
  for (final d in dateTimeSet) {
    final date = dateHelper.onDate(d);
    if (date != null) {
      transformed.add(_DateItem(
        date: d,
        isMonthOnly: !arg.isGroupByDay,
      ));
    }
    if (fileGroups.containsKey(d)) {
      dates.add(d);
      // actual files
      for (final f in fileGroups[d]!..sortedBy((e) => e.fdDateTime).reversed) {
        final item = _buildSingleItem(arg.account, f);
        if (item == null) {
          continue;
        }
        transformed.add(item);
      }
    } else if (arg.summary != null) {
      // summary
      if (!arg.summary!.items.containsKey(d) ||
          arg.itemPerRow == null ||
          arg.itemSize == null) {
        // ???
        continue;
      }
      final summary = arg.summary!.items[d]!;
      for (var i = 0; i < summary.count; ++i) {
        transformed.add(_SummaryFileItem(date: d, index: i));
      }
    }
  }
  return _ItemTransformerResult(
    items: transformed,
    dates: dates,
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

class _ItemMeasurement {
  const _ItemMeasurement({
    required this.itemPerRow,
    required this.itemSize,
  });

  final int itemPerRow;
  final double itemSize;
}

_ItemMeasurement _measureItem(double viewWidth, double maxItemWidth) {
  final maxCountPerRow = viewWidth / maxItemWidth;
  final itemPerRow = maxCountPerRow.ceil();
  final size = viewWidth / itemPerRow;
  return _ItemMeasurement(itemPerRow: itemPerRow, itemSize: size);
}
