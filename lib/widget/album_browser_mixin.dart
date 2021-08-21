import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/lab.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/import_pending_shared_album.dart';
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
  void initCover(Account account, Album album) {
    try {
      final coverFile = album.coverProvider.getCover(album);
      _coverPreviewUrl = api_util.getFilePreviewUrl(account, coverFile!,
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
        if (album.albumFile?.path.startsWith(
                remote_storage_util.getRemotePendingSharedAlbumsDir(account)) ==
            true)
          IconButton(
            onPressed: () => _onAddToCollectionPressed(context, account, album),
            icon: const Icon(Icons.library_add),
            tooltip: "Add to collection",
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
  bool validateEditMode() => true;

  @protected
  void doneEditMode() {}

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

  void _onAddToCollectionPressed(
      BuildContext context, Account account, Album album) async {
    Navigator.of(context).pop();
    var controller = SnackBarManager().showSnackBar(SnackBar(
      content: Text("Adding album '${album.name}' to collection"),
      duration: k.snackBarDurationShort,
    ));
    controller?.closed.whenComplete(() {
      controller = null;
    });
    final fileRepo = FileRepo(FileWebdavDataSource());
    try {
      await ImportPendingSharedAlbum(fileRepo)(account, album.albumFile!);
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text("Added '${album.name}' to collection successfully"),
        duration: k.snackBarDurationNormal,
      ));
    } catch (e, stackTrace) {
      _log.shout(
          "[_onAddToCollectionPressed] Failed while import pending shared album" +
              (kDebugMode ? ": ${album.albumFile?.path}" : ""),
          e,
          stackTrace);
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e, context)),
        duration: k.snackBarDurationNormal,
      ));
    }
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
