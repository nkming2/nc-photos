import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/theme.dart';

class ImageGridItem extends StatelessWidget {
  ImageGridItem({
    Key key,
    @required this.account,
    @required this.imageUrl,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(2),
          child: FittedBox(
            clipBehavior: Clip.hardEdge,
            fit: BoxFit.cover,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              httpHeaders: {
                "Authorization": Api.getAuthorizationHeaderValue(account),
              },
              fadeInDuration: const Duration(),
              filterQuality: FilterQuality.high,
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
            ),
          ),
        ),
        if (isSelected)
          Positioned.fill(
            child: Container(
              color: AppTheme.getSelectionOverlayColor(context),
            ),
          ),
        if (isSelected)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.check_circle_outlined,
                size: 32,
                color: AppTheme.getSelectionCheckColor(context),
              ),
            ),
          ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        )
      ],
    );
  }

  final Account account;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
}
