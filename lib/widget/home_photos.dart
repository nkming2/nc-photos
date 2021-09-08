import 'dart:math' as math;

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/scan_dir.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/primitive.dart';
import 'package:nc_photos/share_handler.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/add_to_album.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/album_picker_dialog.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
import 'package:nc_photos/widget/measure.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/settings.dart';
import 'package:nc_photos/widget/viewer.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';

class HomePhotos extends StatefulWidget {
  HomePhotos({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  createState() => _HomePhotosState();

  final Account account;
}

class _HomePhotosState extends State<HomePhotos>
    with
        SelectableItemStreamListMixin<HomePhotos>,
        RouteAware,
        PageVisibilityMixin,
        TickerProviderStateMixin {
  @override
  initState() {
    super.initState();
    _thumbZoomLevel = Pref.inst().getHomePhotosZoomLevelOr(0);
    _initBloc();
    _metadataTaskStateChangedListener.begin();
  }

  @override
  dispose() {
    _metadataTaskIconController.stop();
    _metadataTaskStateChangedListener.end();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return BlocListener<ScanDirBloc, ScanDirBlocState>(
      bloc: _bloc,
      listener: (context, state) => _onStateChange(context, state),
      child: BlocBuilder<ScanDirBloc, ScanDirBlocState>(
        bloc: _bloc,
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  void _initBloc() {
    _bloc = ScanDirBloc.of(widget.account);
    if (_bloc.state is ScanDirBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        setState(() {
          _onStateChange(context, _bloc.state);
        });
      });
    }
  }

  Widget _buildContent(BuildContext context, ScanDirBlocState state) {
    return LayoutBuilder(builder: (context, constraints) {
      final scrollExtent = _getScrollViewExtent(constraints);
      return Stack(
        children: [
          buildItemStreamListOuter(
            context,
            child: Theme(
              data: Theme.of(context).copyWith(
                accentColor: AppTheme.getOverscrollIndicatorColor(context),
              ),
              child: DraggableScrollbar.semicircle(
                controller: _scrollController,
                overrideMaxScrollExtent: scrollExtent,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildAppBar(context),
                      if (_metadataTaskState != MetadataTaskState.idle)
                        _buildMetadataTaskHeader(context),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        sliver: buildItemStreamList(
                          maxCrossAxisExtent: _thumbSize.toDouble(),
                          onMaxExtentChanged: (value) {
                            setState(() {
                              _itemListMaxExtent = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (state is ScanDirBlocLoading)
            Align(
              alignment: Alignment.bottomCenter,
              child: const LinearProgressIndicator(),
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
        if (platform_k.isAndroid)
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: L10n.global().shareTooltip,
            onPressed: () {
              _onSelectionAppBarSharePressed(context);
            },
          ),
        IconButton(
          icon: const Icon(Icons.playlist_add),
          tooltip: L10n.global().addToAlbumTooltip,
          onPressed: () {
            _onAddToAlbumPressed(context);
          },
        ),
        PopupMenuButton<_SelectionMenuOption>(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          itemBuilder: (context) => [
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
            _onSelectionAppBarMenuSelected(context, option);
          },
        ),
      ],
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return SliverMeasureExtent(
      onChange: (extent) {
        _appBarExtent = extent;
      },
      child: HomeSliverAppBar(
        account: widget.account,
        actions: [
          ZoomMenuButton(
            initialZoom: _thumbZoomLevel,
            minZoom: -1,
            maxZoom: 2,
            onZoomChanged: (value) {
              setState(() {
                _setThumbZoomLevel(value.round());
              });
              Pref.inst().setHomePhotosZoomLevel(_thumbZoomLevel);
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
      ),
    );
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
                        L10n.global().metadataTaskProcessingNotification,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                else if (_metadataTaskState == MetadataTaskState.waitingForWifi)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync_problem,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        L10n.global().metadataTaskPauseNoWiFiNotification,
                        style: TextStyle(fontSize: 12),
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
                          arguments: SettingsArguments(widget.account));
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

  void _onStateChange(BuildContext context, ScanDirBlocState state) {
    if (state is ScanDirBlocInit) {
      itemStreamListItems = [];
    } else if (state is ScanDirBlocSuccess || state is ScanDirBlocLoading) {
      _transformItems(state.files);
      if (state is ScanDirBlocSuccess) {
        if (Pref.inst().isEnableExifOr() && !_hasFiredMetadataTask.value) {
          MetadataTaskManager().addTask(MetadataTask(widget.account));
          _hasFiredMetadataTask.value = true;
        }
      }
    } else if (state is ScanDirBlocFailure) {
      _transformItems(state.files);
      if (isPageVisible()) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception)),
          duration: k.snackBarDurationNormal,
        ));
      }
    } else if (state is ScanDirBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles, index));
  }

  void _onSelectionAppBarSharePressed(BuildContext context) {
    assert(platform_k.isAndroid);
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    ShareHandler().shareFiles(context, widget.account, selected).then((_) {
      setState(() {
        clearSelectedItems();
      });
    });
  }

  Future<void> _onAddToAlbumPressed(BuildContext context) async {
    try {
      final value = await showDialog<Album>(
        context: context,
        builder: (_) => AlbumPickerDialog(
          account: widget.account,
        ),
      );
      if (value == null) {
        // user cancelled the dialog
        return;
      }

      _log.info("[_onAddToAlbumPressed] Album picked: ${value.name}");
      await NotifiedAction(
        () async {
          assert(value.provider is AlbumStaticProvider);
          final selected = selectedListItems
              .whereType<_FileListItem>()
              .map((e) => AlbumFileItem(file: e.file))
              .toList();
          final albumRepo = AlbumRepo(AlbumCachedDataSource());
          await AddToAlbum(albumRepo)(widget.account, value, selected);
          setState(() {
            clearSelectedItems();
          });
        },
        null,
        L10n.global().addSelectedToAlbumSuccessNotification(value.name),
        failureText: L10n.global().addSelectedToAlbumFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout("[_onAddToAlbumPressed] Exception", e, stackTrace);
    }
  }

  Future<void> _onArchivePressed(BuildContext context) async {
    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    await NotifiedListAction<File>(
      list: selectedFiles,
      action: (file) async {
        await UpdateProperty(fileRepo)
            .updateIsArchived(widget.account, file, true);
      },
      processingText: L10n.global()
          .archiveSelectedProcessingNotification(selectedFiles.length),
      successText: L10n.global().archiveSelectedSuccessNotification,
      getFailureText: (failures) =>
          L10n.global().archiveSelectedFailureNotification(failures.length),
      onActionError: (file, e, stackTrace) {
        _log.shout(
            "[_onArchivePressed] Failed while archiving file" +
                (shouldLogFileName ? ": ${file.path}" : ""),
            e,
            stackTrace);
      },
    )();
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    await NotifiedListAction<File>(
      list: selectedFiles,
      action: (file) async {
        await Remove(fileRepo, albumRepo)(widget.account, file);
      },
      processingText: L10n.global()
          .deleteSelectedProcessingNotification(selectedFiles.length),
      successText: L10n.global().deleteSelectedSuccessNotification,
      getFailureText: (failures) =>
          L10n.global().deleteSelectedFailureNotification(failures.length),
      onActionError: (file, e, stackTrace) {
        _log.shout(
            "[_onDeletePressed] Failed while removing file" +
                (shouldLogFileName ? ": ${file.path}" : ""),
            e,
            stackTrace);
      },
    )();
  }

  void _onSelectionAppBarMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
      case _SelectionMenuOption.archive:
        _onArchivePressed(context);
        break;

      case _SelectionMenuOption.delete:
        _onDeletePressed(context);
        break;

      default:
        _log.shout("[_onSelectionAppBarMenuSelected] Unknown option: $option");
        break;
    }
  }

  void _onRefreshSelected() {
    _hasFiredMetadataTask.value = false;
    _reqRefresh();
  }

  void _onMetadataTaskStateChanged(MetadataTaskStateChangedEvent ev) {
    if (ev.state != _metadataTaskState) {
      setState(() {
        _metadataTaskState = ev.state;
      });
    }
  }

  /// Transform a File list to grid items
  void _transformItems(List<File> files) {
    _backingFiles = files
        .where((element) =>
            file_util.isSupportedFormat(element) && element.isArchived != true)
        .sorted(compareFileDateTimeDescending);

    DateTime? currentDate;
    final isMonthOnly = _thumbZoomLevel < 0;
    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];

        final newDate = f.bestDateTime.toLocal();
        if (newDate.year != currentDate?.year ||
            newDate.month != currentDate?.month ||
            (!isMonthOnly && newDate.day != currentDate?.day)) {
          yield _DateListItem(date: newDate, isMonthOnly: isMonthOnly);
          currentDate = newDate;
        }

        final previewUrl = api_util.getFilePreviewUrl(widget.account, f,
            width: _thumbSize, height: _thumbSize);
        if (file_util.isSupportedImageFormat(f)) {
          yield _ImageListItem(
            file: f,
            account: widget.account,
            previewUrl: previewUrl,
            onTap: () => _onItemTap(i),
          );
        } else if (file_util.isSupportedVideoFormat(f)) {
          yield _VideoListItem(
            file: f,
            account: widget.account,
            previewUrl: previewUrl,
            onTap: () => _onItemTap(i),
          );
        } else {
          _log.shout(
              "[_transformItems] Unsupported file format: ${f.contentType}");
        }
      }
    }()
        .toList();
  }

  void _reqQuery() {
    _bloc.add(ScanDirBlocQuery(
        widget.account,
        widget.account.roots
            .map((e) => File(
                path:
                    "${api_util.getWebdavRootUrlRelative(widget.account)}/$e"))
            .toList()));
  }

  void _reqRefresh() {
    _bloc.add(ScanDirBlocRefresh(
        widget.account,
        widget.account.roots
            .map((e) => File(
                path:
                    "${api_util.getWebdavRootUrlRelative(widget.account)}/$e"))
            .toList()));
  }

  void _setThumbZoomLevel(int level) {
    final prevLevel = _thumbZoomLevel;
    _thumbZoomLevel = level;
    if ((prevLevel >= 0) != (level >= 0)) {
      _transformItems(_backingFiles);
    }
  }

  /// Return the estimated scroll extent of the custom scroll view, or null
  double? _getScrollViewExtent(BoxConstraints constraints) {
    if (_itemListMaxExtent != null &&
        constraints.hasBoundedHeight &&
        _appBarExtent != null) {
      final metadataTaskHeaderExtent =
          _metadataTaskState == MetadataTaskState.idle
              ? 0
              : _metadataTaskHeaderHeight;
      // scroll extent = list height - widget viewport height + sliver app bar height + metadata task header height + list padding
      final scrollExtent = _itemListMaxExtent! -
          constraints.maxHeight +
          _appBarExtent! +
          metadataTaskHeaderExtent +
          16;
      _log.info(
          "[_getScrollViewExtent] $_itemListMaxExtent - ${constraints.maxHeight} + $_appBarExtent + $metadataTaskHeaderExtent + 16 = $scrollExtent");
      return scrollExtent;
    } else {
      return null;
    }
  }

  int get _thumbSize {
    switch (_thumbZoomLevel) {
      case -1:
        return 96;

      case 1:
        return 176;

      case 2:
        return 256;

      case 0:
      default:
        return 112;
    }
  }

  Primitive<bool> get _hasFiredMetadataTask {
    final blocId =
        "${widget.account.scheme}://${widget.account.username}@${widget.account.address}";
    try {
      _log.fine("[_hasFiredMetadataTask] Resolving bloc for '$blocId'");
      return KiwiContainer().resolve<Primitive<bool>>(
          "HomePhotosState.hasFiredMetadataTask($blocId)");
    } catch (_) {
      _log.info(
          "[_hasFiredMetadataTask] New bloc instance for account: ${widget.account}");
      final obj = Primitive(false);
      KiwiContainer().registerInstance<Primitive<bool>>(obj,
          name: "HomePhotosState.hasFiredMetadataTask($blocId)");
      return obj;
    }
  }

  late ScanDirBloc _bloc;

  var _backingFiles = <File>[];

  var _thumbZoomLevel = 0;

  final ScrollController _scrollController = ScrollController();

  double? _appBarExtent;
  double? _itemListMaxExtent;

  late final _metadataTaskStateChangedListener =
      AppEventListener<MetadataTaskStateChangedEvent>(
          _onMetadataTaskStateChanged);
  var _metadataTaskState = MetadataTaskManager().state;
  late final _metadataTaskIconController = AnimationController(
    upperBound: 2 * math.pi,
    duration: const Duration(seconds: 10),
    vsync: this,
  )..repeat();

  static final _log = Logger("widget.home_photos._HomePhotosState");
  static const _menuValueRefresh = 0;

  static const _metadataTaskHeaderHeight = 32.0;
}

abstract class _ListItem implements SelectableItem {
  _ListItem({
    VoidCallback? onTap,
  }) : _onTap = onTap;

  @override
  get onTap => _onTap;

  @override
  get isSelectable => true;

  @override
  get staggeredTile => const StaggeredTile.count(1, 1);

  final VoidCallback? _onTap;
}

class _DateListItem extends _ListItem {
  _DateListItem({
    required this.date,
    this.isMonthOnly = false,
  });

  @override
  get isSelectable => false;

  @override
  get staggeredTile => const StaggeredTile.extent(99, 32);

  @override
  buildWidget(BuildContext context) {
    String subtitle = "";
    if (date != null) {
      final pattern =
          isMonthOnly ? DateFormat.YEAR_MONTH : DateFormat.YEAR_MONTH_DAY;
      subtitle =
          DateFormat(pattern, Localizations.localeOf(context).languageCode)
              .format(date!.toLocal());
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.caption!.copyWith(
                color: AppTheme.getPrimaryTextColor(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  final DateTime? date;
  final bool isMonthOnly;
}

abstract class _FileListItem extends _ListItem {
  _FileListItem({
    required this.file,
    VoidCallback? onTap,
  }) : super(onTap: onTap);

  @override
  operator ==(Object other) {
    return other is _FileListItem && file.path == other.file.path;
  }

  @override
  get hashCode => file.path.hashCode;

  final File file;
}

class _ImageListItem extends _FileListItem {
  _ImageListItem({
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(file: file, onTap: onTap);

  @override
  buildWidget(BuildContext context) {
    return PhotoListImage(
      account: account,
      previewUrl: previewUrl,
      isGif: file.contentType == "image/gif",
    );
  }

  final Account account;
  final String previewUrl;
}

class _VideoListItem extends _FileListItem {
  _VideoListItem({
    required File file,
    required this.account,
    required this.previewUrl,
    VoidCallback? onTap,
  }) : super(file: file, onTap: onTap);

  @override
  buildWidget(BuildContext context) {
    return PhotoListVideo(
      account: account,
      previewUrl: previewUrl,
    );
  }

  final Account account;
  final String previewUrl;
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

enum _SelectionMenuOption {
  archive,
  delete,
}
