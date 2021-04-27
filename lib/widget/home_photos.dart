import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/bloc/scan_dir.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/widget/album_picker_dialog.dart';
import 'package:nc_photos/widget/home_app_bar.dart';
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
    with SelectableItemStreamListMixin<HomePhotos> {
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
    return Stack(
      children: [
        buildItemStreamListOuter(
          context,
          child: Theme(
            data: Theme.of(context).copyWith(
              accentColor: AppTheme.getOverscrollIndicatorColor(context),
            ),
            child: CustomScrollView(
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
        if (state is ScanDirBlocLoading)
          Align(
            alignment: Alignment.bottomCenter,
            child: const LinearProgressIndicator(),
          ),
      ],
    );
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
        ],
      ),
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    return HomeSliverAppBar(
      account: widget.account,
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.zoom_in),
          tooltip: AppLocalizations.of(context).zoomTooltip,
          itemBuilder: (context) => [
            PopupMenuZoom(
              initialValue: _thumbZoomLevel,
              onChanged: (value) {
                setState(() {
                  _thumbZoomLevel = value.round();
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
    );
  }

  void _onStateChange(BuildContext context, ScanDirBlocState state) {
    if (state is ScanDirBlocInit) {
      itemStreamListItems = [];
    } else if (state is ScanDirBlocSuccess || state is ScanDirBlocLoading) {
      _transformItems(state.files);
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
      _log.severe(
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
        _log.severe(
            "[_onSelectionAppBarDeletePressed] Failed while removing file: ${f.path}",
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

  void _onRefreshSelected() {
    _reqRefresh();
    if (Pref.inst().isEnableExif()) {
      KiwiContainer()
          .resolve<MetadataTaskManager>()
          .addTask(MetadataTask(widget.account));
    }
  }

  /// Transform a File list to grid items
  void _transformItems(List<File> files) {
    _backingFiles = files
        .where((element) => file_util.isSupportedFormat(element))
        .sorted(compareFileDateTimeDescending);

    String currentDateStr;
    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];
        final newDateStr =
            (f.metadata?.exif?.dateTimeOriginal ?? f.lastModified)
                ?.toSubtitleString();
        if (newDateStr != currentDateStr) {
          yield _SubtitleListItem(subtitle: newDateStr);
          currentDateStr = newDateStr;
        }
        var previewUrl;
        if (f.hasPreview) {
          previewUrl = api_util.getFilePreviewUrl(widget.account, f,
              width: _thumbSize, height: _thumbSize);
        } else {
          previewUrl = api_util.getFileUrl(widget.account, f);
        }
        yield _ImageListItem(
          file: f,
          account: widget.account,
          previewUrl: previewUrl,
          onTap: () => _onItemTap(i),
        );
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

  int get _thumbSize {
    switch (_thumbZoomLevel) {
      case 1:
        return 176;

      case 2:
        return 256;

      case 0:
      default:
        return 112;
    }
  }

  ScanDirBloc _bloc;

  var _backingFiles = <File>[];

  var _thumbZoomLevel = 0;

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
    return FittedBox(
      clipBehavior: Clip.hardEdge,
      fit: BoxFit.cover,
      child: CachedNetworkImage(
        imageUrl: previewUrl,
        httpHeaders: {
          "Authorization": Api.getAuthorizationHeaderValue(account),
        },
        fadeInDuration: const Duration(),
        filterQuality: FilterQuality.high,
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      ),
    );
  }

  final Account account;
  final String previewUrl;
}

extension on DateTime {
  String toSubtitleString() {
    final format = DateFormat(DateFormat.YEAR_MONTH_DAY);
    return format.format(this.toLocal());
  }
}
