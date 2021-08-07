import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/lab.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/widget/album_browser_app_bar.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/share_album_dialog.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';

mixin AlbumBrowserMixin<T extends StatefulWidget>
    on SelectableItemStreamListMixin<T> {
  @override
  initState() {
    super.initState();
    _thumbZoomLevel = Pref.inst().getAlbumBrowserZoomLevelOr(0);
  }

  @protected
  void initCover(Account account, List<File> backingFiles) {
    try {
      final coverFile =
          backingFiles.firstWhere((element) => element.hasPreview ?? false);
      _coverPreviewUrl = api_util.getFilePreviewUrl(account, coverFile,
          width: 1024, height: 600);
    } catch (_) {}
  }

  @protected
  Widget buildNormalAppBar(
    BuildContext context,
    Account account,
    Album album, {
    List<Widget>? actions,
    List<PopupMenuEntry<int>> Function(BuildContext)? menuItemBuilder,
    void Function(int)? onSelectedMenuItem,
  }) {
    return AlbumBrowserAppBar(
      account: account,
      album: album,
      coverPreviewUrl: _coverPreviewUrl,
      actions: [
        ZoomMenuButton(
          initialZoom: _thumbZoomLevel,
          minZoom: 0,
          maxZoom: 2,
          onZoomChanged: (value) {
            setState(() {
              _thumbZoomLevel = value.round();
            });
            Pref.inst().setAlbumBrowserZoomLevel(_thumbZoomLevel);
          },
        ),
        if (album.albumFile!.isOwned(account.username) &&
            Lab().enableSharedAlbum)
          IconButton(
            onPressed: () => _onSharePressed(context, account, album),
            icon: const Icon(Icons.share),
            tooltip: L10n.of(context).shareTooltip,
          ),
        ...(actions ?? []),
        if (menuItemBuilder != null || canEdit)
          PopupMenuButton<int>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            itemBuilder: (context) => [
              if (canEdit)
                PopupMenuItem(
                  value: -1,
                  child: Text(L10n.of(context).editAlbumMenuLabel),
                ),
              ...(menuItemBuilder?.call(context) ?? []),
            ],
            onSelected: (option) {
              if (option >= 0) {
                onSelectedMenuItem?.call(option);
              } else {
                switch (option) {
                  case _menuValueEdit:
                    _onAppBarEditPressed(context, album);
                    break;

                  default:
                    _log.shout("[buildNormalAppBar] Unknown value: $option");
                    break;
                }
              }
            },
          ),
      ],
    );
  }

  @protected
  Widget buildSelectionAppBar(BuildContext context, List<Widget> actions) {
    return SelectionAppBar(
      count: selectedListItems.length,
      onClosePressed: () {
        setState(() {
          clearSelectedItems();
        });
      },
      actions: actions,
    );
  }

  @protected
  Widget buildEditAppBar(
    BuildContext context,
    Account account,
    Album album, {
    List<Widget>? actions,
  }) {
    return AlbumBrowserEditAppBar(
      account: account,
      album: album,
      coverPreviewUrl: _coverPreviewUrl,
      actions: actions,
      onDonePressed: () {
        if (validateEditMode()) {
          setState(() {
            _isEditMode = false;
          });
          doneEditMode();
        }
      },
      onAlbumNameSaved: (value) {
        _editFormValue.name = value;
      },
    );
  }

  @protected
  bool get isEditMode => _isEditMode;

  @protected
  bool get canEdit => true;

  @protected
  @mustCallSuper
  void enterEditMode() {}

  /// Validates the pending modifications
  @protected
  bool validateEditMode();

  @protected
  void doneEditMode();

  /// Return a new album with the edits
  @protected
  Album makeEdited(Album album) {
    return album.copyWith(
      name: _editFormValue.name,
    );
  }

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

  void _onAppBarEditPressed(BuildContext context, Album album) {
    setState(() {
      _isEditMode = true;
      enterEditMode();
      _editFormValue = _EditFormValue();
    });
  }

  void _onSharePressed(BuildContext context, Account account, Album album) {
    showDialog(
      context: context,
      builder: (_) => ShareAlbumDialog(
        account: account,
        file: album.albumFile!,
      ),
    );
  }

  String? _coverPreviewUrl;
  var _thumbZoomLevel = 0;

  var _isEditMode = false;
  var _editFormValue = _EditFormValue();

  static final _log = Logger("widget.album_browser_mixin.AlbumBrowserMixin");
  static const _menuValueEdit = -1;
}

class _EditFormValue {
  late String name;
}
