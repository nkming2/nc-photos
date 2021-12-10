import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/import_pending_shared_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/widget/album_browser_app_bar.dart';
import 'package:nc_photos/widget/album_browser_util.dart' as album_browser_util;
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:nc_photos/widget/selection_app_bar.dart';
import 'package:nc_photos/widget/zoom_menu_button.dart';

mixin AlbumBrowserMixin<T extends StatefulWidget>
    on SelectableItemStreamListMixin<T> {
  @override
  initState() {
    super.initState();
    _thumbZoomLevel = Pref().getAlbumBrowserZoomLevelOr(0);
  }

  @protected
  void initCover(Account account, Album album) {
    try {
      final coverFile = album.coverProvider.getCover(album);
      _coverPreviewUrl = api_util.getFilePreviewUrl(account, coverFile!,
          width: k.coverSize, height: k.coverSize);
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
    final menuItems = [
      if (canEdit)
        PopupMenuItem(
          value: _menuValueEdit,
          child: Text(L10n.global().editAlbumMenuLabel),
        ),
      if (canEdit && album.coverProvider is AlbumManualCoverProvider)
        PopupMenuItem(
          value: _menuValueUnsetCover,
          child: Text(L10n.global().unsetAlbumCoverTooltip),
        ),
    ];
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
            Pref().setAlbumBrowserZoomLevel(_thumbZoomLevel);
          },
        ),
        if (album.albumFile?.path.startsWith(
                remote_storage_util.getRemotePendingSharedAlbumsDir(account)) ==
            true)
          IconButton(
            onPressed: () => _onAddToCollectionPressed(context, account, album),
            icon: const Icon(Icons.library_add),
            tooltip: L10n.global().addToCollectionTooltip,
          ),
        ...(actions ?? []),
        if (menuItemBuilder != null || menuItems.isNotEmpty)
          PopupMenuButton<int>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            itemBuilder: (context) => [
              ...menuItems,
              ...(menuItemBuilder?.call(context) ?? []),
            ],
            onSelected: (option) => _onMenuOptionSelected(
                option, account, album, onSelectedMenuItem),
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

  void _onMenuOptionSelected(int option, Account account, Album album,
      void Function(int)? onSelectedMenuItem) {
    if (option >= 0) {
      onSelectedMenuItem?.call(option);
    } else {
      switch (option) {
        case _menuValueEdit:
          _onAppBarEditPressed(album);
          break;

        case _menuValueUnsetCover:
          _onUnsetCoverPressed(account, album);
          break;

        default:
          _log.shout("[_onMenuOptionSelected] Unknown value: $option");
          break;
      }
    }
  }

  void _onAppBarEditPressed(Album album) {
    setState(() {
      _isEditMode = true;
      enterEditMode();
      _editFormValue = _EditFormValue();
    });
  }

  Future<void> _onUnsetCoverPressed(Account account, Album album) async {
    _log.info("[_onUnsetCoverPressed] Unset album cover for '${album.name}'");
    try {
      await NotifiedAction(
        () async {
          final albumRepo = AlbumRepo(AlbumCachedDataSource(AppDb()));
          await UpdateAlbum(albumRepo)(
              account,
              album.copyWith(
                coverProvider: AlbumAutoCoverProvider(),
              ));
        },
        L10n.global().unsetAlbumCoverProcessingNotification,
        L10n.global().unsetAlbumCoverSuccessNotification,
        failureText: L10n.global().unsetAlbumCoverFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout(
          "[_onUnsetCoverPressed] Failed while updating album", e, stackTrace);
    }
  }

  void _onAddToCollectionPressed(
      BuildContext context, Account account, Album album) async {
    Album? newAlbum;
    try {
      await NotifiedAction(
        () async {
          newAlbum = await ImportPendingSharedAlbum(
              KiwiContainer().resolve<DiContainer>())(account, album);
        },
        L10n.global().addToCollectionProcessingNotification(album.name),
        L10n.global().addToCollectionSuccessNotification(album.name),
      )();
    } catch (e, stackTrace) {
      _log.shout(
          "[_onAddToCollectionPressed] Failed while ImportPendingSharedAlbum: ${logFilename(album.albumFile?.path)}",
          e,
          stackTrace);
    }
    if (newAlbum != null) {
      album_browser_util.pushReplacement(context, account, newAlbum!);
    }
  }

  String? _coverPreviewUrl;
  var _thumbZoomLevel = 0;

  var _isEditMode = false;
  var _editFormValue = _EditFormValue();

  static final _log = Logger("widget.album_browser_mixin.AlbumBrowserMixin");
  static const _menuValueEdit = -1;
  static const _menuValueUnsetCover = -2;
}

class _EditFormValue {
  late String name;
}
