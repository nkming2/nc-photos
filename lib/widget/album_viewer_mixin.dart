import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
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
    List<PopupMenuEntry<int>> Function(BuildContext) menuItemBuilder,
    void Function(int) onSelectedMenuItem,
  }) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: _getAppBarCover(context, account),
        title: Text(
          album.name,
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(context),
          ),
        ),
      ),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.photo_size_select_large),
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
        PopupMenuButton(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: -1,
              child: Text(AppLocalizations.of(context).editAlbumMenuLabel),
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

  @protected
  Widget buildEditAppBar(
    BuildContext context,
    Account account,
    Album album, {
    List<Widget> actions,
  }) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: _getAppBarCover(context, account),
        title: TextFormField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).nameInputHint,
          ),
          validator: (value) {
            if (value.isEmpty) {
              return AppLocalizations.of(context).albumNameInputInvalidEmpty;
            }
            return null;
          },
          onSaved: (value) {
            _editFormValue.name = value;
          },
          onChanged: (value) {
            // need to save the value otherwise it'll return to the initial
            // after scrolling out of the view
            _editNameValue = value;
          },
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(context),
          ),
          initialValue: _editNameValue,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.check),
        color: Theme.of(context).colorScheme.primary,
        tooltip: AppLocalizations.of(context).doneButtonTooltip,
        onPressed: () {
          if (validateEditMode()) {
            setState(() {
              _isEditMode = false;
            });
            doneEditMode();
          }
        },
      ),
      actions: actions,
    );
  }

  @protected
  get isEditMode => _isEditMode;

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
      _editNameValue = album.name;
      _editFormValue = _EditFormValue();
    });
  }

  Widget _getAppBarCover(BuildContext context, Account account) {
    try {
      if (_coverPreviewUrl != null) {
        return Opacity(
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
    return null;
  }

  String _coverPreviewUrl;
  var _thumbZoomLevel = 0;

  var _isEditMode = false;
  String _editNameValue;
  var _editFormValue = _EditFormValue();

  static final _log = Logger("widget.album_viewer_mixin.AlbumViewerMixin");
  static const _menuValueEdit = -1;
}

class _EditFormValue {
  String name;
}
