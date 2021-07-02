import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/popup_menu_zoom.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';

mixin AlbumViewerMixin<T extends StatefulWidget>
    on SelectableItemStreamListMixin<T> {
  @override
  initState() {
    super.initState();
    _thumbZoomLevel = Pref.inst().getAlbumViewerZoomLevel(0);
  }

  @protected
  File initCover(Account account, List<File> backingFiles) {
    try {
      final coverFile =
          backingFiles.firstWhere((element) => element.hasPreview);
      _coverPreviewUrl = api_util.getFilePreviewUrl(account, coverFile,
          width: 1024, height: 600);
      return coverFile;
    } catch (_) {
      return null;
    }
  }

  @protected
  Widget buildNormalAppBar(
    BuildContext context,
    Account account,
    Album album, {
    List<Widget> actions,
  }) {
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
                "Authorization": Api.getAuthorizationHeaderValue(account),
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
          album.name,
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
        ...(actions ?? []),
      ],
    );
  }

  @protected
  Widget buildSelectionAppBar(BuildContext context, List<Widget> actions) {
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
        actions: actions,
      ),
    );
  }

  @override
  get itemStreamListCellSize => thumbSize;

  @protected
  int get thumbSize {
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

  String _coverPreviewUrl;
  var _thumbZoomLevel = 0;
}
