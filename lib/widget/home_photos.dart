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
import 'package:nc_photos/widget/image_grid_item.dart';
import 'package:nc_photos/widget/popup_menu_zoom.dart';
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

class _HomePhotosState extends State<HomePhotos> {
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

  void _initBloc() {
    ScanDirBloc bloc;
    final blocId =
        "${widget.account.scheme}://${widget.account.username}@${widget.account.address}?${widget.account.roots.join('&')}";
    try {
      _log.fine("[_initBloc] Resolving bloc for '$blocId'");
      bloc = KiwiContainer().resolve<ScanDirBloc>("ScanDirBloc($blocId)");
    } catch (e) {
      // no created instance for this account, make a new one
      _log.info("[_initBloc] New bloc instance for account: ${widget.account}");
      bloc = ScanDirBloc();
      KiwiContainer()
          .registerInstance<ScanDirBloc>(bloc, name: "ScanDirBloc($blocId)");
    }

    _bloc = bloc;
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
        Theme(
          data: Theme.of(context).copyWith(
            accentColor: AppTheme.getOverscrollIndicatorColor(context),
          ),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverStaggeredGrid.extentBuilder(
                  // need to rebuild grid after zoom level changed
                  key: ValueKey(_thumbZoomLevel),
                  maxCrossAxisExtent: _thumbSize.toDouble(),
                  itemCount: _items.length,
                  itemBuilder: _buildItem,
                  staggeredTileBuilder: (index) {
                    if (_items[index] is _GridSubtitleItem) {
                      return const StaggeredTile.extent(99, 32);
                    } else {
                      return const StaggeredTile.count(1, 1);
                    }
                  },
                ),
              ),
            ],
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
    if (_isSelectionMode) {
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
              _selectedItems.clear();
            });
          },
        ),
        title: Text(AppLocalizations.of(context)
            .selectionAppBarTitle(_selectedItems.length)),
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

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    if (item is _GridSubtitleItem) {
      return _buildSubtitleItem(context, item, index);
    } else if (item is _GridImageItem) {
      return _buildImageItem(context, item, index);
    } else {
      _log.severe("[_buildItem] Unsupported item type: ${item.runtimeType}");
      throw StateError("Unsupported item type: ${item.runtimeType}");
    }
  }

  Widget _buildSubtitleItem(
      BuildContext context, _GridSubtitleItem item, int index) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        item.subtitle,
        style: Theme.of(context).textTheme.caption.copyWith(
              color: Theme.of(context).textTheme.bodyText1.color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, _GridImageItem item, int index) {
    return ImageGridItem(
      account: widget.account,
      imageUrl: item.previewUrl,
      isSelected: _selectedItems.contains(item),
      onTap: () => _onItemTap(item, index),
      onLongPress:
          _isSelectionMode ? null : () => _onItemLongPress(item, index),
    );
  }

  void _onStateChange(BuildContext context, ScanDirBlocState state) {
    if (state is ScanDirBlocInit) {
      _items.clear();
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

  void _onItemTap(_GridFileItem item, int index) {
    if (_isSelectionMode) {
      if (!_items.contains(item)) {
        _log.warning("[_onItemTap] Item not found in backing list, ignoring");
        return;
      }
      if (_selectedItems.contains(item)) {
        // unselect
        setState(() {
          _selectedItems.remove(item);
        });
      } else {
        // select
        setState(() {
          _selectedItems.add(item);
        });
      }
    } else {
      final fileIndex = _itemIndexToFileIndex(index);
      Navigator.pushNamed(context, Viewer.routeName,
          arguments: ViewerArguments(widget.account, _backingFiles, fileIndex));
    }
  }

  void _onItemLongPress(_GridFileItem item, int index) {
    if (!_items.contains(item)) {
      _log.warning(
          "[_onItemLongPress] Item not found in backing list, ignoring");
      return;
    }
    setState(() {
      _selectedItems.add(item);
    });
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
        _log.info("[_onSelectionAppBarAddToAlbumPressed] Album picked: $value");
        _addSelectedToAlbum(context, value).then((_) {
          setState(() {
            _selectedItems.clear();
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
    final selectedItems = _selectedItems
        .whereType<_GridFileItem>()
        .map((e) => AlbumFileItem(file: e.file))
        .toList();
    try {
      final albumRepo = AlbumRepo(AlbumCachedDataSource());
      await UpdateAlbum(albumRepo)(
          widget.account,
          album.copyWith(
            items: [
              ...album.items,
              ...selectedItems,
            ],
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
          .deleteSelectedProcessingNotification(_selectedItems.length)),
      duration: k.snackBarDurationShort,
    ));
    final selectedFiles =
        _selectedItems.whereType<_GridFileItem>().map((e) => e.file).toList();
    setState(() {
      _selectedItems.clear();
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
    _reqQuery();
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

    _items.clear();
    String currentDateStr;
    for (final f in _backingFiles) {
      final newDateStr = (f.metadata?.exif?.dateTimeOriginal ?? f.lastModified)
          ?.toSubtitleString();
      if (newDateStr != currentDateStr) {
        _items.add(_GridItem.subtitle(newDateStr));
        currentDateStr = newDateStr;
      }
      var previewUrl;
      if (f.hasPreview) {
        previewUrl = api_util.getFilePreviewUrl(widget.account, f,
            width: _thumbSize, height: _thumbSize);
      } else {
        previewUrl = api_util.getFileUrl(widget.account, f);
      }
      _items.add(_GridItem.image(f, previewUrl));
    }

    _transformSelectedItems();
  }

  /// Map selected items to the new item list
  void _transformSelectedItems() {
    final newSelectedItems = _selectedItems
        .map((from) {
          try {
            return _items
                .whereType<_GridFileItem>()
                .firstWhere((to) => from.file.path == to.file.path);
          } catch (_) {
            return null;
          }
        })
        .where((element) => element != null)
        .toList();
    _selectedItems
      ..clear()
      ..addAll(newSelectedItems);
  }

  /// Convert a grid item index to its corresponding file index
  ///
  /// These two indices differ when there's non file-based item on screen
  int _itemIndexToFileIndex(int itemIndex) {
    var fileIndex = 0;
    final itemIt = _items.iterator;
    for (int i = 0; i < itemIndex; ++i) {
      if (!itemIt.moveNext()) {
        // ???
        break;
      }
      if (itemIt.current is _GridFileItem) {
        ++fileIndex;
      }
    }
    return fileIndex;
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

  bool get _isSelectionMode => _selectedItems.isNotEmpty;

  ScanDirBloc _bloc;

  final _items = <_GridItem>[];
  var _backingFiles = <File>[];

  var _thumbZoomLevel = 0;

  final _selectedItems = <_GridFileItem>[];

  static final _log = Logger("widget.home_photos._HomePhotosState");
  static const _menuValueRefresh = 0;
}

abstract class _GridItem {
  const _GridItem();

  factory _GridItem.subtitle(String val) => _GridSubtitleItem(val);

  factory _GridItem.image(File file, String previewUrl) =>
      _GridImageItem(file, previewUrl);
}

class _GridSubtitleItem extends _GridItem {
  _GridSubtitleItem(this.subtitle);

  final String subtitle;
}

abstract class _GridFileItem extends _GridItem {
  _GridFileItem(this.file);

  final File file;
}

class _GridImageItem extends _GridFileItem {
  _GridImageItem(File file, this.previewUrl) : super(file);

  final String previewUrl;
}

extension on DateTime {
  String toSubtitleString() {
    final format = DateFormat(DateFormat.YEAR_MONTH_DAY);
    return format.format(this.toLocal());
  }
}
