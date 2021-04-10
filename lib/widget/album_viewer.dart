import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/widget/image_grid_item.dart';
import 'package:nc_photos/widget/popup_menu_zoom.dart';
import 'package:nc_photos/widget/viewer.dart';

class AlbumViewerArguments {
  AlbumViewerArguments(this.account, this.album);

  final Account account;
  final Album album;
}

class AlbumViewer extends StatefulWidget {
  static const routeName = "/album-viewer";

  AlbumViewer({
    Key key,
    @required this.account,
    @required this.album,
  }) : super(key: key);

  AlbumViewer.fromArgs(AlbumViewerArguments args, {Key key})
      : this(
          key: key,
          account: args.account,
          album: args.album,
        );

  @override
  createState() => _AlbumViewerState();

  final Account account;
  final Album album;
}

class _AlbumViewerState extends State<AlbumViewer>
    with TickerProviderStateMixin {
  @override
  initState() {
    super.initState();
    _album = widget.album;
    _transformItems();
    _initCover();
    _thumbZoomLevel = Pref.inst().getAlbumViewerZoomLevel(0);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(builder: (context) => _buildContent(context)),
      ),
    );
  }

  void _initCover() {
    try {
      final coverFile = _backingFiles.first;
      if (coverFile.hasPreview) {
        _coverPreviewUrl = api_util.getFilePreviewUrl(widget.account, coverFile,
            width: 1024, height: 600);
      } else {
        _coverPreviewUrl = api_util.getFileUrl(widget.account, coverFile);
      }
    } catch (_) {}
  }

  Widget _buildContent(BuildContext context) {
    return Theme(
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
              staggeredTileBuilder: (index) => const StaggeredTile.count(1, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (_isSelectionMode) {
      return _buildSelectionAppBar(context);
    } else {
      return _buildNormalAppBar(context);
    }
  }

  Widget _buildSelectionAppBar(BuildContext context) {
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
            icon: const Icon(Icons.remove),
            tooltip:
                AppLocalizations.of(context).removeSelectedFromAlbumTooltip,
            onPressed: () {
              _onSelectionAppBarRemovePressed();
            },
          )
        ],
      ),
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    Widget cover;
    try {
      if (_coverPreviewUrl != null) {
        cover = Opacity(
          opacity: 0.25,
          child: FittedBox(
            clipBehavior: Clip.hardEdge,
            fit: BoxFit.cover,
            child: CachedNetworkImage(
              imageUrl: _coverPreviewUrl,
              httpHeaders: {
                "Authorization":
                    Api.getAuthorizationHeaderValue(widget.account),
              },
              filterQuality: FilterQuality.high,
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
            ),
          ),
        );
      }
    } catch (_) {}

    return SliverAppBar(
      floating: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: cover,
        title: Text(
          _album.name,
          style: TextStyle(
            color: Theme.of(context).textTheme.headline6.color,
          ),
        ),
      ),
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
                Pref.inst().setAlbumViewerZoomLevel(_thumbZoomLevel);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    if (item is _GridImageItem) {
      return _buildImageItem(context, item, index);
    } else {
      _log.severe("[_buildItem] Unsupported item type: ${item.runtimeType}");
      throw StateError("Unsupported item type: ${item.runtimeType}");
    }
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

  void _onItemTap(_GridItem item, int index) {
    if (_isSelectionMode) {
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
      Navigator.pushNamed(context, Viewer.routeName,
          arguments: ViewerArguments(widget.account, _backingFiles, index));
    }
  }

  void _onItemLongPress(_GridItem item, int index) {
    setState(() {
      _selectedItems.add(item);
    });
  }

  void _onSelectionAppBarRemovePressed() {
    // currently album's are auto sorted by date, so it's ok to remove items w/o
    // preserving the order. this will be problematic if we want to allow custom
    // sorting later
    final selectedIndexes =
        _selectedItems.map((e) => _items.indexOf(e)).toList();
    final selectedFiles = _backingFiles.takeIndex(selectedIndexes).toList();
    final newItems = _album.items.where((element) {
      if (element is AlbumFileItem) {
        return !selectedFiles.contains(element.file);
      } else {
        return true;
      }
    }).toList();
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    final newAlbum = _album.copyWith(
      items: newItems,
    );
    UpdateAlbum(albumRepo)(widget.account, newAlbum).then((_) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)
            .removeSelectedFromAlbumSuccessNotification(
                selectedIndexes.length)),
        duration: k.snackBarDurationNormal,
      ));
      setState(() {
        _album = newAlbum;
        _transformItems();
      });
    }).catchError((e, stacktrace) {
      _log.severe("[_onSelectionRemovePressed] Failed while updating album", e,
          stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            "${AppLocalizations.of(context).removeSelectedFromAlbumFailureNotification}: "
            "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
    });
    setState(() {
      _selectedItems.clear();
    });
  }

  void _transformItems() {
    _backingFiles = _album.items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) => file_util.isSupportedFormat(element))
        .sorted(compareFileDateTimeDescending);

    _items.clear();
    _items.addAll(_backingFiles.map((e) {
      var previewUrl;
      if (e.hasPreview) {
        previewUrl = api_util.getFilePreviewUrl(widget.account, e,
            width: _thumbSize, height: _thumbSize);
      } else {
        previewUrl = api_util.getFileUrl(widget.account, e);
      }
      return _GridItem.image(previewUrl);
    }));
  }

  int get _thumbSize {
    switch (_thumbZoomLevel) {
      case 1:
        return 192;

      case 2:
        return 256;

      case 0:
      default:
        return 112;
    }
  }

  bool get _isSelectionMode => _selectedItems.isNotEmpty;

  Album _album;
  final _items = <_GridItem>[];
  var _backingFiles = <File>[];

  String _coverPreviewUrl;
  var _thumbZoomLevel = 0;

  final _selectedItems = <_GridItem>[];

  static final _log = Logger("widget.album_viewer._AlbumViewerState");
}

class _GridItem {
  const _GridItem();

  factory _GridItem.image(String previewUrl) => _GridImageItem(previewUrl);
}

class _GridImageItem extends _GridItem {
  _GridImageItem(this.previewUrl);

  final String previewUrl;
}
