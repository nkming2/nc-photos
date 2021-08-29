import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/theme.dart';

class AlbumBrowserAppBar extends StatelessWidget {
  AlbumBrowserAppBar({
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

class AlbumBrowserEditAppBar extends StatefulWidget {
  AlbumBrowserEditAppBar({
    Key? key,
    required this.account,
    required this.album,
    this.coverPreviewUrl,
    this.actions,
    required this.onDonePressed,
    required this.onAlbumNameSaved,
  }) : super(key: key);

  @override
  createState() => _AlbumBrowserEditAppBarState();

  final Account account;
  final Album album;
  final String? coverPreviewUrl;
  final List<Widget>? actions;
  final VoidCallback? onDonePressed;
  final ValueChanged<String>? onAlbumNameSaved;
}

class _AlbumBrowserEditAppBarState extends State<AlbumBrowserEditAppBar> {
  @override
  initState() {
    super.initState();
    _controller = TextEditingController(text: widget.album.name);
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
          controller: _controller,
          decoration: InputDecoration(
            hintText: L10n.global().nameInputHint,
          ),
          validator: (_) {
            // use _controller.text here because the value might be wrong if
            // user scrolled the app bar off screen
            if (_controller.text.isNotEmpty == true) {
              return null;
            } else {
              return L10n.global().albumNameInputInvalidEmpty;
            }
          },
          onSaved: (_) {
            widget.onAlbumNameSaved?.call(_controller.text);
          },
          style: TextStyle(
            color: AppTheme.getPrimaryTextColor(context),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.check),
        color: Theme.of(context).colorScheme.primary,
        tooltip: L10n.global().doneButtonTooltip,
        onPressed: widget.onDonePressed,
      ),
      actions: widget.actions,
    );
  }

  late TextEditingController _controller;
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
