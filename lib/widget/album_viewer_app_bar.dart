import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/theme.dart';

class AlbumViewerAppBar extends StatelessWidget {
  AlbumViewerAppBar({
    Key? key,
    required this.account,
    required this.album,
    this.coverPreviewUrl,
    this.actions,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: _getAppBarCover(context, account, coverPreviewUrl),
        title: Text(
          album.name,
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(context),
          ),
        ),
      ),
      actions: actions,
    );
  }

  final Account account;
  final Album album;
  final String? coverPreviewUrl;
  final List<Widget>? actions;
}

class AlbumViewerEditAppBar extends StatefulWidget {
  AlbumViewerEditAppBar({
    Key? key,
    required this.account,
    required this.album,
    this.coverPreviewUrl,
    this.actions,
    required this.onDonePressed,
    required this.onAlbumNameSaved,
  }) : super(key: key);

  @override
  createState() => _AlbumViewerEditAppBarState();

  final Account account;
  final Album album;
  final String? coverPreviewUrl;
  final List<Widget>? actions;
  final VoidCallback? onDonePressed;
  final ValueChanged<String>? onAlbumNameSaved;
}

class _AlbumViewerEditAppBarState extends State<AlbumViewerEditAppBar> {
  @override
  initState() {
    super.initState();
    _editNameValue = widget.album.name;
  }

  @override
  build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background:
            _getAppBarCover(context, widget.account, widget.coverPreviewUrl),
        title: TextFormField(
          decoration: InputDecoration(
            hintText: L10n.of(context).nameInputHint,
          ),
          validator: (value) {
            if (value?.isNotEmpty == true) {
              return null;
            } else {
              return L10n.of(context).albumNameInputInvalidEmpty;
            }
          },
          onSaved: (value) {
            widget.onAlbumNameSaved?.call(value!);
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
        tooltip: L10n.of(context).doneButtonTooltip,
        onPressed: widget.onDonePressed,
      ),
      actions: widget.actions,
    );
  }

  late String _editNameValue;
}

Widget? _getAppBarCover(
    BuildContext context, Account account, String? coverPreviewUrl) {
  try {
    if (coverPreviewUrl != null) {
      return Opacity(
        opacity: Theme.of(context).brightness == Brightness.light ? 0.25 : 0.35,
        child: FittedBox(
          clipBehavior: Clip.hardEdge,
          fit: BoxFit.cover,
          child: CachedNetworkImage(
            imageUrl: coverPreviewUrl,
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
