import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/bloc/progress.dart';
import 'package:nc_photos/bloc/scan_account_dir.dart';
import 'package:nc_photos/compute_queue.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/download_handler.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/event/native_event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/primitive.dart';
import 'package:nc_photos/service.dart' as service;
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/startup_sync.dart';
import 'package:nc_photos/widget/album_browser_util.dart' as album_browser_util;
import 'package:nc_photos/widget/builder/photo_list_item_builder.dart';
import 'package:nc_photos/widget/handler/add_selection_to_album_handler.dart';
import 'package:nc_photos/widget/handler/archive_selection_handler.dart';
import 'package:nc_photos/widget/handler/double_tap_exit_handler.dart';
import 'package:nc_photos/widget/handler/remove_selection_handler.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
import 'package:nc_photos/widget/network_thumbnail.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/photo_list_util.dart' as photo_list_util;
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/settings.dart';
import 'package:nc_photos/widget/viewer.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:visibility_detector/visibility_detector.dart';

part 'home_photos.g.dart';

class HomePhotos extends StatefulWidget {
  const HomePhotos({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  createState() => _HomePhotosState();

  final Account account;
}

@npLog
class _HomePhotosState extends State<HomePhotos>
    with
        SelectableItemStreamListMixin<HomePhotos>,
        RouteAware,
        PageVisibilityMixin,
        TickerProviderStateMixin {
  @override
  initState() {
    super.initState();
    _thumbZoomLevel = Pref().getHomePhotosZoomLevelOr(0);
    _initBloc();
    _web?.onInitState();
    _prefUpdatedListener.begin();
    _imageProcessorUploadSuccessListener?.begin();
  }

  @override
  dispose() {
    _prefUpdatedListener.end();
    _imageProcessorUploadSuccessListener?.end();
    _web?.onDispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return BlocListener<ScanAccountDirBloc, ScanAccountDirBlocState>(
      bloc: _bloc,
      listener: (context, state) => _onStateChange(context, state),
      child: _buildContent(context),
    );
  }

  @override
  onItemTap(SelectableItem item, int index) {
    item.as<PhotoListFileItem>()?.run((fileItem) {
      Navigator.pushNamed(
        context,
        Viewer.routeName,
        arguments:
            ViewerArguments(widget.account, _backingFiles, fileItem.fileIndex),
      );
    });
  }

  @override
  onVisibilityChanged(VisibilityInfo info, int index, SelectableItem item) {
    if (info.visibleFraction >= 0.2) {
      _visibleItems.add(_VisibleItem(index, item));
    } else {
      _visibleItems.remove(_VisibleItem(index, item));
    }
    _visibilityThrottler.trigger(
        maxResponceTime: const Duration(milliseconds: 500));
  }

  @override
  onBackButtonPressed() async {
    if (isSelectionMode) {
      return super.onBackButtonPressed();
    } else {
      return DoubleTapExitHandler()();
    }
  }

  void _initBloc() {
    if (_bloc.state is ScanAccountDirBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _onStateChange(context, _bloc.state);
          });
        }
      });
    }
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final scrollExtent = _getScrollViewExtent(context, constraints);
      return Stack(
        children: [
          buildItemStreamListOuter(
            context,
            child: DraggableScrollbar.semicircle(
              controller: _scrollController,
              overrideMaxScrollExtent: scrollExtent,
              // status bar + app bar
              topOffset: _calcAppBarExtent(context),
              bottomOffset: _calcBottomAppBarExtent(context),
              labelTextBuilder: (_) => _buildScrollLabel(context),
              labelPadding: const EdgeInsets.symmetric(horizontal: 40),
              backgroundColor: Theme.of(context)
                  .elevate(Theme.of(context).colorScheme.inverseSurface, 3),
              enabled: _isScrollbarVisible,
              heightScrollThumb: 60,
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: RefreshIndicator(
                  onRefresh: () async {
                    _onRefreshSelected();
                    await _waitRefresh();
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildAppBar(context),
                      _web?.buildContent(context),
                      if (AccountPref.of(widget.account)
                              .isEnableMemoryAlbumOr(true) &&
                          _smartAlbums.isNotEmpty)
                        _buildSmartAlbumList(context),
                      BlocBuilder<ScanAccountDirBloc, ScanAccountDirBlocState>(
                        bloc: _bloc,
                        builder: (context, state) {
                          if (_isInitialSync(state)) {
                            return _InitialLoadingProgress(
                              progressBloc: _queryProgressBloc,
                            );
                          } else {
                            return buildItemStreamList(
                              maxCrossAxisExtent: _thumbSize.toDouble(),
                              onMaxExtentChanged: (value) {
                                setState(() {
                                  _itemListMaxExtent = value;
                                });
                              },
                              isEnableVisibilityCallback: true,
                            );
                          }
                        },
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _calcBottomAppBarExtent(context),
                        ),
                      ),
                    ].whereNotNull().toList(),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              height: _calcBottomAppBarExtent(context),
              child: ClipRect(
                child: BackdropFilter(
                  filter: Theme.of(context).appBarBlurFilter,
                  child: const ColoredBox(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAppBar(BuildContext context) {
    if (isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return _buildNormalAppBar(context);
    }
  }

  Widget _buildSelectionAppBar(BuildContext conetxt) {
    return SelectionAppBar(
      count: selectedListItems.length,
      onClosePressed: () {
        setState(() {
          clearSelectedItems();
        });
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: L10n.global().shareTooltip,
          onPressed: () {
            _onSelectionSharePressed(context);
          },
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: L10n.global().addToAlbumTooltip,
          onPressed: () {
            _onSelectionAddToAlbumPressed(context);
          },
        ),
        PopupMenuButton<_SelectionMenuOption>(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _SelectionMenuOption.download,
              child: Text(L10n.global().downloadTooltip),
            ),
            PopupMenuItem(
              value: _SelectionMenuOption.archive,
              child: Text(L10n.global().archiveTooltip),
            ),
            PopupMenuItem(
              value: _SelectionMenuOption.delete,
              child: Text(L10n.global().deleteTooltip),
            ),
          ],
          onSelected: (option) {
            _onSelectionMenuSelected(context, option);
          },
        ),
      ],
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return BlocBuilder<ScanAccountDirBloc, ScanAccountDirBlocState>(
      bloc: _bloc,
      buildWhen: (previous, current) {
        if (previous is ScanAccountDirBlocLoading &&
            current is ScanAccountDirBlocLoading) {
          // both loading, check if initial flag changed
          return previous.isInitialLoad != current.isInitialLoad;
        } else {
          // check if any one is loading == state changed from/to loading
          return previous is ScanAccountDirBlocLoading ||
              current is ScanAccountDirBlocLoading;
        }
      },
      builder: (context, state) {
        return HomeSliverAppBar(
          account: widget.account,
          isShowProgressIcon: !_isInitialSync(state) &&
              (state is ScanAccountDirBlocLoading ||
                  _buildItemQueue.isProcessing) &&
              !_isRefreshIndicatorActive,
          actions: [
            ZoomMenuButton(
              initialZoom: _thumbZoomLevel,
              minZoom: -1,
              maxZoom: 2,
              onZoomChanged: (value) {
                _setThumbZoomLevel(value.round());
                Pref().setHomePhotosZoomLevel(_thumbZoomLevel);
              },
            ),
          ],
          menuActions: [
            PopupMenuItem(
              value: _menuValueRefresh,
              child: Text(L10n.global().refreshMenuLabel),
            ),
          ],
          onSelectedMenuActions: (option) {
            switch (option) {
              case _menuValueRefresh:
                _onRefreshSelected();
                break;
            }
          },
        );
      },
    );
  }

  Widget _buildSmartAlbumList(BuildContext context) {
    return SliverToBoxAdapter(
      child: _SmartAlbumList(
        account: widget.account,
        albums: _smartAlbums,
      ),
    );
  }

  Widget _buildScrollLabel(BuildContext context) {
    final firstVisibleItem = _visibleItems
        .sorted()
        .firstWhereOrNull((e) => e.item is PhotoListFileItem);
    final date =
        firstVisibleItem?.item.as<PhotoListFileItem>()?.file.fdDateTime;
    if (date != null) {
      final text = DateFormat(DateFormat.YEAR_ABBR_MONTH,
              Localizations.localeOf(context).languageCode)
          .format(date.toLocal());
      return _ScrollLabel(
        child: Text(text),
      );
    } else {
      return const SizedBox();
    }
  }

  void _onStateChange(BuildContext context, ScanAccountDirBlocState state) {
    if (state is ScanAccountDirBlocInit) {
      itemStreamListItems = [];
    } else if (state is ScanAccountDirBlocSuccess) {
      _transformItems(state.files, isPostSuccess: true);
    } else if (state is ScanAccountDirBlocLoading) {
      if (state.files.length > ScanAccountDirBloc.scanMiniCount) {
        _isScrollbarVisible = true;
      }
      _transformItems(state.files);
    } else if (state is ScanAccountDirBlocFailure) {
      _isScrollbarVisible = true;
      _transformItems(state.files);
      if (isPageVisible()) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception)),
          duration: k.snackBarDurationNormal,
        ));
      }
    } else if (state is ScanAccountDirBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onRefreshSelected() {
    _hasFiredMetadataTask.value = false;
    _reqRefresh();
  }

  void _onSelectionMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
      case _SelectionMenuOption.archive:
        _onSelectionArchivePressed(context);
        break;
      case _SelectionMenuOption.delete:
        _onSelectionDeletePressed(context);
        break;
      case _SelectionMenuOption.download:
        _onSelectionDownloadPressed();
        break;
      default:
        _log.shout("[_onSelectionMenuSelected] Unknown option: $option");
        break;
    }
  }

  void _onSelectionSharePressed(BuildContext context) {
    final c = KiwiContainer().resolve<DiContainer>();
    final selected = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    ShareHandler(
      c,
      context: context,
      clearSelection: () {
        setState(() {
          clearSelectedItems();
        });
      },
    ).shareFiles(widget.account, selected);
  }

  Future<void> _onSelectionAddToAlbumPressed(BuildContext context) {
    final c = KiwiContainer().resolve<DiContainer>();
    return AddSelectionToAlbumHandler(c)(
      context: context,
      account: widget.account,
      selection: selectedListItems
          .whereType<PhotoListFileItem>()
          .map((e) => e.file)
          .toList(),
      clearSelection: () {
        if (mounted) {
          setState(() {
            clearSelectedItems();
          });
        }
      },
    );
  }

  void _onSelectionDownloadPressed() {
    final c = KiwiContainer().resolve<DiContainer>();
    final selected = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    DownloadHandler(c).downloadFiles(widget.account, selected);
    setState(() {
      clearSelectedItems();
    });
  }

  Future<void> _onSelectionArchivePressed(BuildContext context) async {
    final c = KiwiContainer().resolve<DiContainer>();
    final selectedFiles = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    await ArchiveSelectionHandler(c)(
      account: widget.account,
      selection: selectedFiles,
    );
  }

  Future<void> _onSelectionDeletePressed(BuildContext context) async {
    final c = KiwiContainer().resolve<DiContainer>();
    final selectedFiles = selectedListItems
        .whereType<PhotoListFileItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    await RemoveSelectionHandler(c)(
      account: widget.account,
      selection: selectedFiles,
      isMoveToTrash: true,
    );
  }

  void _onPrefUpdated(PrefUpdatedEvent ev) {
    if (ev.key == PrefKey.enableExif) {
      if (ev.value == true) {
        _tryStartMetadataTask(ignoreFired: true);
      } else {
        _stopMetadataTask();
      }
    } else if (ev.key == PrefKey.isPhotosTabSortByName) {
      if (_bloc.state is! ScanAccountDirBlocInit) {
        _log.info("[_onPrefUpdated] Update view after changing sort option");
        _transformItems(_bloc.state.files);
      }
    } else if (ev.key == PrefKey.memoriesRange) {
      if (_bloc.state is! ScanAccountDirBlocInit) {
        _log.info("[_onPrefUpdated] Update view after changing memories");
        _transformItems(_bloc.state.files);
      }
    }
  }

  void _onImageProcessorUploadSuccessEvent(
      ImageProcessorUploadSuccessEvent ev) {
    _log.info(
        "[_onImageProcessorUploadSuccessEvent] Scheduling metadata task after next refresh");
    _hasFiredMetadataTask.value = false;
  }

  Future<void> _tryStartMetadataTask({
    bool ignoreFired = false,
  }) async {
    if (_bloc.state is ScanAccountDirBlocSuccess &&
        Pref().isEnableExifOr() &&
        (!_hasFiredMetadataTask.value || ignoreFired)) {
      try {
        final c = KiwiContainer().resolve<DiContainer>();
        final missingMetadataCount = await c.sqliteDb.use((db) async {
          return await db.countMissingMetadataByFileIds(
            appAccount: widget.account,
            fileIds: _backingFiles.map((e) => e.fdId).toList(),
          );
        });
        _log.info(
            "[_tryStartMetadataTask] Missing count: $missingMetadataCount");
        if (missingMetadataCount > 0) {
          if (_web != null) {
            _web!.startMetadataTask(missingMetadataCount);
          } else {
            unawaited(service.startService());
          }
        }

        _hasFiredMetadataTask.value = true;
      } catch (e, stackTrace) {
        _log.shout("[_tryStartMetadataTask] Failed starting metadata task", e,
            stackTrace);
      }
    }
  }

  void _stopMetadataTask() {
    if (_web == null) {
      service.stopService();
    }
  }

  Future<void> _startupSync() async {
    if (!_hasResyncedFavorites.value) {
      _hasResyncedFavorites.value = true;
      unawaited(StartupSync.runInIsolate(widget.account));
    }
  }

  /// Transform a File list to grid items
  void _transformItems(
    List<FileDescriptor> files, {
    bool isSorted = false,
    bool isPostSuccess = false,
  }) {
    _log.info("[_transformItems] Queue ${files.length} items");
    final c = KiwiContainer().resolve<DiContainer>();
    final PhotoListItemSorter? sorter;
    final PhotoListItemGrouper? grouper;
    if (Pref().isPhotosTabSortByNameOr()) {
      sorter = isSorted ? null : photoListFilenameSorter;
      grouper = null;
    } else {
      sorter = isSorted ? null : photoListFileDateTimeSorter;
      grouper = PhotoListFileDateGrouper(isMonthOnly: _thumbZoomLevel < 0);
    }

    _buildItemQueue.addJob(
      PhotoListItemBuilderArguments(
        widget.account,
        files,
        sorter: sorter,
        grouper: grouper,
        smartAlbumConfig:
            PhotoListItemSmartAlbumConfig(c.pref.getMemoriesRangeOr()),
        shouldShowFavoriteBadge: true,
        locale: language_util.getSelectedLocale() ??
            PlatformDispatcher.instance.locale,
      ),
      buildPhotoListItem,
      (result) {
        if (mounted) {
          setState(() {
            _backingFiles = result.backingFiles;
            itemStreamListItems = result.listItems;
            _smartAlbums = result.smartAlbums;

            if (isPostSuccess) {
              _isScrollbarVisible = true;
              _startupSync();
              _tryStartMetadataTask();
            }
          });
        }
      },
    );
  }

  void _reqQuery() {
    _bloc.add(ScanAccountDirBlocQuery(
      progressBloc: _queryProgressBloc,
    ));
  }

  void _reqRefresh() {
    _bloc.add(const ScanAccountDirBlocRefresh());
  }

  Future<void> _waitRefresh() async {
    setState(() {
      _isRefreshIndicatorActive = true;
    });
    try {
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        if (_bloc.state is! ScanAccountDirBlocLoading) {
          return;
        }
      }
    } finally {
      // To prevent the app bar icon appearing for a very short while
      unawaited(Future.delayed(const Duration(seconds: 2)).then((_) {
        if (mounted) {
          setState(() {
            _isRefreshIndicatorActive = false;
          });
        }
      }));
    }
  }

  void _setThumbZoomLevel(int level) {
    final prevLevel = _thumbZoomLevel;
    if ((prevLevel >= 0) != (level >= 0)) {
      _thumbZoomLevel = level;
      _transformItems(_backingFiles, isSorted: true);
    } else {
      setState(() {
        _thumbZoomLevel = level;
      });
    }
  }

  /// Return the estimated scroll extent of the custom scroll view, or null
  double? _getScrollViewExtent(
      BuildContext context, BoxConstraints constraints) {
    if (_itemListMaxExtent != null && constraints.hasBoundedHeight) {
      final appBarExtent = _calcAppBarExtent(context);
      final bottomAppBarExtent = _calcBottomAppBarExtent(context);
      final metadataTaskHeaderExtent = _web?.getHeaderHeight() ?? 0;
      final smartAlbumListHeight =
          AccountPref.of(widget.account).isEnableMemoryAlbumOr(true) &&
                  _smartAlbums.isNotEmpty
              ? _SmartAlbumItem.height
              : 0;
      // scroll extent = list height - widget viewport height
      // + sliver app bar height + bottom app bar height
      // + metadata task header height + smart album list height
      final scrollExtent = _itemListMaxExtent! -
          constraints.maxHeight +
          appBarExtent +
          bottomAppBarExtent +
          metadataTaskHeaderExtent +
          smartAlbumListHeight;
      _log.info(
          "[_getScrollViewExtent] $_itemListMaxExtent - ${constraints.maxHeight} + $appBarExtent + $bottomAppBarExtent + $metadataTaskHeaderExtent + $smartAlbumListHeight = $scrollExtent");
      return scrollExtent;
    } else {
      return null;
    }
  }

  bool _isInitialSync(ScanAccountDirBlocState state) =>
      state is ScanAccountDirBlocLoading &&
      state.files.isEmpty &&
      state.isInitialLoad;

  double _calcAppBarExtent(BuildContext context) =>
      MediaQuery.of(context).padding.top + kToolbarHeight;

  double _calcBottomAppBarExtent(BuildContext context) =>
      NavigationBarTheme.of(context).height!;

  Primitive<bool> get _hasFiredMetadataTask {
    final name = bloc_util.getInstNameForRootAwareAccount(
        "HomePhotosState.hasFiredMetadataTask", widget.account);
    try {
      _log.fine("[_hasFiredMetadataTask] Resolving for '$name'");
      return KiwiContainer().resolve<Primitive<bool>>(name);
    } catch (_) {
      _log.info(
          "[_hasFiredMetadataTask] New instance for account: ${widget.account}");
      final obj = Primitive(false);
      KiwiContainer().registerInstance<Primitive<bool>>(obj, name: name);
      return obj;
    }
  }

  Primitive<bool> get _hasResyncedFavorites {
    final name = bloc_util.getInstNameForRootAwareAccount(
        "HomePhotosState._hasResyncedFavorites", widget.account);
    try {
      _log.fine("[_hasResyncedFavorites] Resolving for '$name'");
      return KiwiContainer().resolve<Primitive<bool>>(name);
    } catch (_) {
      _log.info(
          "[_hasResyncedFavorites] New instance for account: ${widget.account}");
      final obj = Primitive(false);
      KiwiContainer().registerInstance<Primitive<bool>>(obj, name: name);
      return obj;
    }
  }

  late final _bloc = ScanAccountDirBloc.of(widget.account);
  late final _queryProgressBloc = ProgressBloc();

  var _backingFiles = <FileDescriptor>[];
  var _smartAlbums = <Album>[];

  final _buildItemQueue =
      ComputeQueue<PhotoListItemBuilderArguments, PhotoListItemBuilderResult>();

  var _thumbZoomLevel = 0;
  int get _thumbSize => photo_list_util.getThumbSize(_thumbZoomLevel);

  final ScrollController _scrollController = ScrollController();

  double? _itemListMaxExtent;

  final _visibleItems = HashSet<_VisibleItem>();
  late final _visibilityThrottler = Throttler(onTriggered: (_) {
    // label text is always 1 frame behind, so we need to update the text for
    // the last frame
    if (mounted) {
      _log.fine("[_visibilityThrottler] Update screen");
      setState(() {});
    }
  });

  late final _prefUpdatedListener =
      AppEventListener<PrefUpdatedEvent>(_onPrefUpdated);
  late final _imageProcessorUploadSuccessListener = platform_k.isWeb
      ? null
      : NativeEventListener<ImageProcessorUploadSuccessEvent>(
          _onImageProcessorUploadSuccessEvent);

  late final _Web? _web = platform_k.isWeb ? _Web(this) : null;

  var _isScrollbarVisible = false;
  var _isRefreshIndicatorActive = false;

  static const _menuValueRefresh = 0;
}

class _Web {
  _Web(this.state);

  void onInitState() {
    _metadataTaskStateChangedListener.begin();
    _filePropertyUpdatedListener.begin();
  }

  void onDispose() {
    _metadataTaskIconController.stop();
    _metadataTaskStateChangedListener.end();
    _filePropertyUpdatedListener.end();
  }

  Widget? buildContent(BuildContext context) {
    if (_metadataTaskState != MetadataTaskState.idle) {
      return _buildMetadataTaskHeader(context);
    } else {
      return null;
    }
  }

  void startMetadataTask(int missingMetadataCount) {
    final c = KiwiContainer().resolve<DiContainer>();
    MetadataTaskManager().addTask(MetadataTask(
        c, state.widget.account, AccountPref.of(state.widget.account)));
    _metadataTaskProcessTotalCount = missingMetadataCount;
  }

  double getHeaderHeight() {
    return _metadataTaskState == MetadataTaskState.idle
        ? 0
        : _metadataTaskHeaderHeight;
  }

  Widget _buildMetadataTaskHeader(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _MetadataTaskHeaderDelegate(
        extent: _metadataTaskHeaderHeight,
        builder: (context) => Container(
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (_metadataTaskState == MetadataTaskState.prcoessing)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MetadataTaskLoadingIcon(
                        controller: _metadataTaskIconController,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        L10n.global().metadataTaskProcessingNotification +
                            _getMetadataTaskProgressString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                else if (_metadataTaskState == MetadataTaskState.waitingForWifi)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync_problem,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        L10n.global().metadataTaskPauseNoWiFiNotification,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                else if (_metadataTaskState == MetadataTaskState.lowBattery)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sync_problem,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        L10n.global().metadataTaskPauseLowBatteryNotification,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                Expanded(
                  child: Container(),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        L10n.global().configButtonLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pushNamed(Settings.routeName,
                          arguments: SettingsArguments(state.widget.account));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onMetadataTaskStateChanged(MetadataTaskStateChangedEvent ev) {
    if (ev.state == MetadataTaskState.idle) {
      _metadataTaskProcessCount = 0;
    }
    if (ev.state != _metadataTaskState) {
      // ignore: invalid_use_of_protected_member
      state.setState(() {
        _metadataTaskState = ev.state;
      });
    }
  }

  void _onFilePropertyUpdated(FilePropertyUpdatedEvent ev) {
    if (!ev.hasAnyProperties([
      FilePropertyUpdatedEvent.propMetadata,
      FilePropertyUpdatedEvent.propImageLocation,
    ])) {
      return;
    }
    // ignore: invalid_use_of_protected_member
    state.setState(() {
      ++_metadataTaskProcessCount;
    });
  }

  String _getMetadataTaskProgressString() {
    if (_metadataTaskProcessTotalCount == 0) {
      return "";
    }
    final clippedCount =
        math.min(_metadataTaskProcessCount, _metadataTaskProcessTotalCount - 1);
    return " ($clippedCount/$_metadataTaskProcessTotalCount)";
  }

  final _HomePhotosState state;

  late final _metadataTaskStateChangedListener =
      AppEventListener<MetadataTaskStateChangedEvent>(
          _onMetadataTaskStateChanged);
  var _metadataTaskState = MetadataTaskManager().state;
  late final _filePropertyUpdatedListener =
      AppEventListener<FilePropertyUpdatedEvent>(_onFilePropertyUpdated);
  var _metadataTaskProcessCount = 0;
  var _metadataTaskProcessTotalCount = 0;
  late final _metadataTaskIconController = AnimationController(
    upperBound: 2 * math.pi,
    duration: const Duration(seconds: 10),
    vsync: state,
  )..repeat();

  static const _metadataTaskHeaderHeight = 32.0;
}

class _MetadataTaskHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _MetadataTaskHeaderDelegate({
    required this.extent,
    required this.builder,
  });

  @override
  build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return builder(context);
  }

  @override
  get maxExtent => extent;

  @override
  get minExtent => maxExtent;

  @override
  shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;

  final double extent;
  final Widget Function(BuildContext context) builder;
}

class _MetadataTaskLoadingIcon extends AnimatedWidget {
  const _MetadataTaskLoadingIcon({
    Key? key,
    required AnimationController controller,
  }) : super(key: key, listenable: controller);

  @override
  build(BuildContext context) {
    return Transform.rotate(
      angle: -_progress.value,
      child: const Icon(
        Icons.sync,
        size: 16,
      ),
    );
  }

  Animation<double> get _progress => listenable as Animation<double>;
}

class _SmartAlbumList extends StatelessWidget {
  const _SmartAlbumList({
    required this.account,
    required this.albums,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _SmartAlbumItem.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final a = albums[index];
          final coverFile = a.coverProvider.getCover(a);
          return _SmartAlbumItem(
            account: account,
            previewUrl: coverFile == null
                ? null
                : NetworkRectThumbnail.imageUrlForFile(account, coverFile),
            label: a.name,
            onTap: () {
              album_browser_util.push(context, account, a);
            },
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
      ),
    );
  }

  final Account account;
  final List<Album> albums;
}

class _SmartAlbumItem extends StatelessWidget {
  static const width = 96.0;
  static const height = width * 1.15;

  const _SmartAlbumItem({
    Key? key,
    required this.account,
    required this.previewUrl,
    required this.label,
    this.onTap,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoListImage(
                account: account,
                previewUrl: previewUrl,
                padding: const EdgeInsets.all(0),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).onDarkSurface,
                          ),
                    ),
                  ),
                ),
              ),
              if (onTap != null)
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onTap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  final Account account;
  final String? previewUrl;
  final String label;
  final VoidCallback? onTap;
}

enum _SelectionMenuOption {
  archive,
  delete,
  download,
}

class _VisibleItem implements Comparable<_VisibleItem> {
  const _VisibleItem(this.index, this.item);

  @override
  operator ==(Object other) => other is _VisibleItem && other.index == index;

  @override
  compareTo(_VisibleItem other) => index.compareTo(other.index);

  @override
  get hashCode => index.hashCode;

  final int index;
  final SelectableItem item;
}

class _InitialLoadingProgress extends StatelessWidget {
  const _InitialLoadingProgress({
    required this.progressBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressBlocState>(
      bloc: progressBloc,
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Theme.of(context).widthLimitedContentMaxWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.global().initialSyncMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: state.progress == 0 ? null : state.progress,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.text ?? "",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  final ProgressBloc progressBloc;
}

class _ScrollLabel extends StatelessWidget {
  const _ScrollLabel({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DefaultTextStyle(
        style: theme.textTheme.titleMedium!
            .copyWith(color: theme.colorScheme.onInverseSurface),
        child: child,
      ),
    );
  }

  final Widget child;
}
