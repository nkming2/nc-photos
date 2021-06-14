import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
import 'package:nc_photos/widget/photo_list_item.dart';
import 'package:nc_photos/widget/popup_menu_zoom.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
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
    with WidgetsBindingObserver, SelectableItemStreamListMixin<AlbumViewer> {
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

  @override
  get itemStreamListCellSize => _thumbSize;

  void _initCover() {
    try {
      final coverFile =
          _backingFiles.firstWhere((element) => element.hasPreview);
      _coverPreviewUrl = api_util.getFilePreviewUrl(widget.account, coverFile,
          width: 1024, height: 600);
    } catch (_) {}
  }

  Widget _buildContent(BuildContext context) {
    return buildItemStreamListOuter(
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
    );
  }

  Widget _buildAppBar(BuildContext context) {
    if (isSelectionMode) {
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
              clearSelectedItems();
            });
          },
        ),
        title: Text(AppLocalizations.of(context)
            .selectionAppBarTitle(selectedListItems.length)),
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
          opacity:
              Theme.of(context).brightness == Brightness.light ? 0.25 : 0.35,
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
              errorWidget: (context, url, error) {
                // just leave it empty
                return Container();
              },
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
            color: AppTheme.getPrimaryTextColor(context),
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
              minValue: 0,
              maxValue: 2,
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

  void _onItemTap(int index) {
    Navigator.pushNamed(context, Viewer.routeName,
        arguments: ViewerArguments(widget.account, _backingFiles, index));
  }

  void _onSelectionAppBarRemovePressed() {
    // currently album's are auto sorted by date, so it's ok to remove items w/o
    // preserving the order. this will be problematic if we want to allow custom
    // sorting later
    final selectedIndexes =
        selectedListItems.map((e) => itemStreamListItems.indexOf(e)).toList();
    final selectedFiles = _backingFiles.takeIndex(selectedIndexes).toList();
    final newItems = _album.items.where((element) {
      if (element is AlbumFileItem) {
        return !selectedFiles.any((select) => select.path == element.file.path);
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
        _initCover();
      });
    }).catchError((e, stacktrace) {
      _log.shout("[_onSelectionRemovePressed] Failed while updating album", e,
          stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            "${AppLocalizations.of(context).removeSelectedFromAlbumFailureNotification}: "
            "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
    });
    setState(() {
      clearSelectedItems();
    });
  }

  void _transformItems() {
    _backingFiles = _album.items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) => file_util.isSupportedFormat(element))
        .sorted(compareFileDateTimeDescending);

    itemStreamListItems = () sync* {
      for (int i = 0; i < _backingFiles.length; ++i) {
        final f = _backingFiles[i];

        final previewUrl = api_util.getFilePreviewUrl(widget.account, f,
            width: _thumbSize, height: _thumbSize);
        if (file_util.isSupportedImageFormat(f)) {
          yield _ImageListItem(
            account: widget.account,
            previewUrl: previewUrl,
            onTap: () => _onItemTap(i),
          );
        } else if (file_util.isSupportedVideoFormat(f)) {
          yield _VideoListItem(
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

  Album _album;
  var _backingFiles = <File>[];

  String _coverPreviewUrl;
  var _thumbZoomLevel = 0;

  static final _log = Logger("widget.album_viewer._AlbumViewerState");
}

class _ImageListItem extends SelectableItemStreamListItem {
  _ImageListItem({
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
  }) : super(onTap: onTap, isSelectable: true);

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

class _VideoListItem extends SelectableItemStreamListItem {
  _VideoListItem({
    @required this.account,
    @required this.previewUrl,
    VoidCallback onTap,
  }) : super(onTap: onTap, isSelectable: true);

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
