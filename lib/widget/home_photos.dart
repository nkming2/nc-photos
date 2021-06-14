import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/bloc/scan_dir.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/primitive.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/album_picker_dialog.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
import 'package:nc_photos/widget/measure.dart';
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/popup_menu_zoom.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/viewer.dart';

class HomePhotos extends StatefulWidget {
  HomePhotos({
    Key key,
    @required this.account,
  }) : super(key: key);

  @override
  createState() => _HomePhotosState();

  final Account account;
}

class _HomePhotosState extends State<HomePhotos>
    with WidgetsBindingObserver, SelectableItemStreamListMixin<HomePhotos> {
  @override
  initState() {
    super.initState();
    _initBloc();
    _thumbZoomLevel = Pref.inst().getHomePhotosZoomLevel(0);
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

  @override
  void onMaxExtentChanged(double maxExtent) {
    setState(() {});
  }

  @override
  int get itemStreamListCellSize => _thumbSize;

  void _initBloc() {
    _bloc = ScanDirBloc.of(widget.account);
    if (_bloc.state is ScanDirBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      _onStateChange(context, _bloc.state);
    }
  }

  Widget _buildContent(BuildContext context, ScanDirBlocState state) {
    return LayoutBuilder(builder: (context, constraints) {
      if (_prevListWidth == null) {
        _prevListWidth = constraints.maxWidth;
      }
      if (constraints.maxWidth != _prevListWidth) {
        _log.info(
            "[_buildContent] updateListHeight: list viewport width changed");
        WidgetsBinding.instance.addPostFrameCallback((_) => updateListHeight());
        _prevListWidth = constraints.maxWidth;
      }

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
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: buildItemStreamList(context),
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
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppTheme.getContextualAppBarTheme(context),
      ),
      child: SliverAppBar(
        pinned: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () {
            setState(() {
              clearSelectedItems();
            });
          },
        ),
        title: Text(AppLocalizations.of(context)
            .selectionAppBarTitle(selectedListItems.length)),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: AppLocalizations.of(context).addSelectedToAlbumTooltip,
            onPressed: () {
              _onSelectionAppBarAddToAlbumPressed(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: AppLocalizations.of(context).deleteSelectedTooltip,
            onPressed: () {
              _onSelectionAppBarDeletePressed(context);
            },
          ),
          PopupMenuButton(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SelectionAppBarMenuOption.archive,
                child:
                    Text(AppLocalizations.of(context).archiveSelectedMenuLabel),
              ),
            ],
            onSelected: (option) {
              _onSelectionAppBarMenuSelected(context, option);
            },
          ),
        ],
      ),
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
          PopupMenuButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: AppLocalizations.of(context).zoomTooltip,
            itemBuilder: (context) => [
              PopupMenuZoom(
                initialValue: _thumbZoomLevel,
                minValue: -1,
                maxValue: 2,
                onChanged: (value) {
                  setState(() {
                    _setThumbZoomLevel(value.round());
                  });
                  Pref.inst().setHomePhotosZoomLevel(_thumbZoomLevel);
                },
              ),
            ],
          ),
        ],
        menuActions: [
          PopupMenuItem(
            value: _menuValueRefresh,
            child: Text(AppLocalizations.of(context).refreshMenuLabel),
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

  void _onStateChange(BuildContext context, ScanDirBlocState state) {
    if (state is ScanDirBlocInit) {
      itemStreamListItems = [];
    } else if (state is ScanDirBlocSuccess || state is ScanDirBlocLoading) {
      _transformItems(state.files);
      if (state is ScanDirBlocSuccess) {
        if (Pref.inst().isEnableExif() && !_hasFiredMetadataTask.value) {
          KiwiContainer()
              .resolve<MetadataTaskManager>()
              .addTask(MetadataTask(widget.account));
          _hasFiredMetadataTask.value = true;
        }
      }
    } else if (state is ScanDirBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception, context)),
        duration: k.snackBarDurationNormal,
      ));
    } else if (state is ScanDirBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onItemTap(int index) {
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles, index));
  }

  void _onSelectionAppBarAddToAlbumPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlbumPickerDialog(
        account: widget.account,
      ),
    ).then((value) {
      if (value == null) {
        // user cancelled the dialog
      } else if (value is Album) {
        _log.info(
            "[_onSelectionAppBarAddToAlbumPressed] Album picked: ${value.name}");
        _addSelectedToAlbum(context, value).then((_) {
          setState(() {
            clearSelectedItems();
          });
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)
                .addSelectedToAlbumSuccessNotification(value.name)),
            duration: k.snackBarDurationNormal,
          ));
        }).catchError((_) {});
      } else {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)
              .addSelectedToAlbumFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
      }
    }).catchError((e, stacktrace) {
      _log.severe(
          "[_onSelectionAppBarAddToAlbumPressed] Failed while showDialog",
          e,
          stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            "${AppLocalizations.of(context).addSelectedToAlbumFailureNotification}: "
            "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
    });
  }

  Future<void> _addSelectedToAlbum(BuildContext context, Album album) async {
    final selected = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => AlbumFileItem(file: e.file))
        .toList();
    try {
      final albumRepo = AlbumRepo(AlbumCachedDataSource());
      await UpdateAlbum(albumRepo)(
          widget.account,
          album.copyWith(
            items: makeDistinctAlbumItems([
              ...album.items,
              ...selected,
            ]),
          ));
    } catch (e, stacktrace) {
      _log.shout(
          "[_addSelectedToAlbum] Failed while updating album", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            "${AppLocalizations.of(context).addSelectedToAlbumFailureNotification}: "
            "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
      rethrow;
    }
  }

  Future<void> _onSelectionAppBarDeletePressed(BuildContext context) async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)
          .deleteSelectedProcessingNotification(selectedListItems.length)),
      duration: k.snackBarDurationShort,
    ));
    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await Remove(fileRepo, albumRepo)(widget.account, f);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarDeletePressed] Failed while removing file" +
                (kDebugMode ? ": ${f.path}" : ""),
            e,
            stacktrace);
        failures.add(f);
      }
    }
    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context).deleteSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)
            .deleteSelectedFailureNotification(failures.length)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onSelectionAppBarMenuSelected(
      BuildContext context, _SelectionAppBarMenuOption option) {
    switch (option) {
      case _SelectionAppBarMenuOption.archive:
        _onSelectionAppBarArchivePressed(context);
        break;

      default:
        _log.shout("[_onSelectionAppBarMenuSelected] Unknown option: $option");
        break;
    }
  }

  Future<void> _onSelectionAppBarArchivePressed(BuildContext context) async {
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)
          .archiveSelectedProcessingNotification(selectedListItems.length)),
      duration: k.snackBarDurationShort,
    ));
    final selectedFiles = selectedListItems
        .whereType<_FileListItem>()
        .map((e) => e.file)
        .toList();
    setState(() {
      clearSelectedItems();
    });
    final fileRepo = FileRepo(FileCachedDataSource());
    final failures = <File>[];
    for (final f in selectedFiles) {
      try {
        await UpdateProperty(fileRepo)
            .updateIsArchived(widget.account, f, true);
      } catch (e, stacktrace) {
        _log.shout(
            "[_onSelectionAppBarArchivePressed] Failed while archiving file" +
                (kDebugMode ? ": ${f.path}" : ""),
            e,
            stacktrace);
        failures.add(f);
      }
    }
    if (failures.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context).archiveSelectedSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)
            .archiveSelectedFailureNotification(failures.length)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onRefreshSelected() {
    _hasFiredMetadataTask.value = false;
    _reqRefresh();
  }

  /// Transform a File list to grid items
  void _transformItems(List<File> files) {
    _backingFiles = files
        .where((element) =>
            file_util.isSupportedFormat(element) && element.isArchived != true)
        .sorted(compareFileDateTimeDescending);

    String currentDateStr;
    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];

        String newDateStr;
        final date = f.metadata?.exif?.dateTimeOriginal ?? f.lastModified;
        if (date == null) {
          newDateStr = "";
        } else if (_thumbZoomLevel >= 0) {
          // daily
          newDateStr = date.toDailySubtitleString();
        } else {
          // monthly
          newDateStr = date.toMonthlySubtitleString();
        }
        if (newDateStr != currentDateStr) {
          yield _SubtitleListItem(subtitle: newDateStr);
          currentDateStr = newDateStr;
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
    }();
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
  double _getScrollViewExtent(BoxConstraints constraints) {
    if (calculatedMaxExtent != null &&
        constraints.hasBoundedHeight &&
        _appBarExtent != null) {
      // scroll extent = list height - widget viewport height + sliver app bar height
      final scrollExtent =
          calculatedMaxExtent - constraints.maxHeight + _appBarExtent;
      _log.info(
          "[_getScrollViewExtent] $calculatedMaxExtent - ${constraints.maxHeight} + $_appBarExtent = $scrollExtent");
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

  ScanDirBloc _bloc;

  var _backingFiles = <File>[];

  var _thumbZoomLevel = 0;

  final ScrollController _scrollController = ScrollController();

  double _prevListWidth;
  double _appBarExtent;

  static final _log = Logger("widget.home_photos._HomePhotosState");
  static const _menuValueRefresh = 0;
}

class _SubtitleListItem extends SelectableItemStreamListItem {
  _SubtitleListItem({
    @required this.subtitle,
  }) : super(staggeredTile: const StaggeredTile.extent(99, 32));

  @override
  buildWidget(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        subtitle,
        style: Theme.of(context).textTheme.caption.copyWith(
              color: AppTheme.getPrimaryTextColor(context),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  final String subtitle;
}

abstract class _FileListItem extends SelectableItemStreamListItem {
  _FileListItem({
    @required this.file,
    VoidCallback onTap,
  }) : super(onTap: onTap, isSelectable: true);

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
    @required File file,
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
  }) : super(file: file, onTap: onTap);

  @override
  buildWidget(BuildContext context) {
    return PhotoListImage(
      account: account,
      previewUrl: previewUrl,
    );
  }

  final Account account;
  final String previewUrl;
}

class _VideoListItem extends _FileListItem {
  _VideoListItem({
    @required File file,
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
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

enum _SelectionAppBarMenuOption {
  archive,
}

extension on DateTime {
  String toDailySubtitleString() {
    final format = DateFormat(DateFormat.YEAR_MONTH_DAY);
    return format.format(this.toLocal());
  }

  String toMonthlySubtitleString() {
    final format = DateFormat(DateFormat.YEAR_MONTH);
    return format.format(this.toLocal());
  }
}
