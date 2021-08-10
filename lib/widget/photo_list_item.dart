import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/theme.dart';

class PhotoListImage extends StatelessWidget {
  const PhotoListImage({
    Key? key,
    required this.account,
    required this.previewUrl,
    this.isGif = false,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return FittedBox(
      clipBehavior: Clip.hardEdge,
      fit: BoxFit.cover,
      child: Stack(
        children: [
          Container(
            // arbitrary size here
            constraints: BoxConstraints.tight(const Size(128, 128)),
            color: AppTheme.getListItemBackgroundColor(context),
            child: CachedNetworkImage(
              imageUrl: previewUrl,
              httpHeaders: {
                "Authorization": Api.getAuthorizationHeaderValue(account),
              },
              fadeInDuration: const Duration(),
              filterQuality: FilterQuality.high,
              errorWidget: (context, url, error) {
                // won't work on web because the image is downloaded by the cache
                // manager instead
                // where's the preview???
                return Container(
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.white.withOpacity(.8),
                    ),
                  ),
                );
              },
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
            ),
          ),
          if (isGif)
            Container(
              // arbitrary size here
              constraints: BoxConstraints.tight(const Size(128, 128)),
              alignment: AlignmentDirectional.topEnd,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: const Icon(
                Icons.gif,
                size: 36,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  final Account account;
  final String previewUrl;
  final bool isGif;
}

class PhotoListVideo extends StatelessWidget {
  const PhotoListVideo({
    Key? key,
    required this.account,
    required this.previewUrl,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return FittedBox(
      clipBehavior: Clip.hardEdge,
      fit: BoxFit.cover,
      child: Stack(
        children: [
          Container(
            // arbitrary size here
            constraints: BoxConstraints.tight(const Size(128, 128)),
            color: AppTheme.getListItemBackgroundColor(context),
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
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.white.withOpacity(.8),
                    ),
                  ),
                );
              },
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
            ),
          ),
          Container(
            // arbitrary size here
            constraints: BoxConstraints.tight(const Size(128, 128)),
            alignment: AlignmentDirectional.topEnd,
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.play_circle_outlined,
              size: 24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  final Account account;
  final String previewUrl;
}

class PhotoListLabel extends StatelessWidget {
  const PhotoListLabel({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.subtitle1,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  final String text;
}

class PhotoListLabelEdit extends PhotoListLabel {
  const PhotoListLabelEdit({
    Key? key,
    required String text,
    required this.onEditPressed,
  }) : super(key: key, text: text);

  @override
  build(BuildContext context) {
    return Stack(
      children: [
        // needed to expand the touch sensitive area to the whole row
        Container(
          color: Colors.transparent,
        ),
        super.build(context),
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: 0,
          child: IconButton(
            icon: Icon(Icons.edit),
            tooltip: L10n.of(context).editTooltip,
            onPressed: onEditPressed,
          ),
        ),
      ],
    );
  }

  final VoidCallback? onEditPressed;
}
