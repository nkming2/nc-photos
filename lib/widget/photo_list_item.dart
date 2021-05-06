import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/theme.dart';

class PhotoListImage extends StatelessWidget {
  const PhotoListImage({
    Key key,
    @required this.account,
    @required this.previewUrl,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return FittedBox(
      clipBehavior: Clip.hardEdge,
      fit: BoxFit.cover,
      child: CachedNetworkImage(
        imageUrl: previewUrl,
        httpHeaders: {
          "Authorization": Api.getAuthorizationHeaderValue(account),
        },
        fadeInDuration: const Duration(),
        filterQuality: FilterQuality.high,
        errorWidget: (context, url, error) {
          // where's the preview???
          return Container(
            color: AppTheme.getListItemBackgroundColor(context),
            width: 128,
            height: 128,
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 56,
                color: Colors.white.withOpacity(.8),
              ),
            ),
          );
        },
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      ),
    );
  }

  final Account account;
  final String previewUrl;
}

class PhotoListVideo extends StatelessWidget {
  const PhotoListVideo({
    Key key,
    @required this.account,
    @required this.previewUrl,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return FittedBox(
      clipBehavior: Clip.hardEdge,
      fit: BoxFit.cover,
      child: CachedNetworkImage(
        imageUrl: previewUrl,
        httpHeaders: {
          "Authorization": Api.getAuthorizationHeaderValue(account),
        },
        fadeInDuration: const Duration(),
        filterQuality: FilterQuality.high,
        errorWidget: (context, url, error) {
          // no preview for this video. Normal since video preview is disabled
          // by default
          return Container(
            color: AppTheme.getListItemBackgroundColor(context),
            width: 128,
            height: 128,
            child: Center(
              child: Icon(
                Icons.videocam,
                size: 56,
                color: Colors.white.withOpacity(.8),
              ),
            ),
          );
        },
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      ),
    );
  }

  final Account account;
  final String previewUrl;
}
