import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/theme.dart';

class PhotoListImage extends StatelessWidget {
  const PhotoListImage({
    Key? key,
    required this.account,
    required this.previewUrl,
    this.padding = const EdgeInsets.all(2),
    this.isGif = false,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Padding(
      padding: padding,
      child: FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: Stack(
          children: [
            Container(
              // arbitrary size here
              constraints: BoxConstraints.tight(const Size(128, 128)),
              color: AppTheme.getListItemBackgroundColor(context),
              child: previewUrl == null
                  ? Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.white.withOpacity(.8),
                      ),
                    )
                  : CachedNetworkImage(
                      cacheManager: ThumbnailCacheManager.inst,
                      imageUrl: previewUrl!,
                      httpHeaders: {
                        "Authorization":
                            Api.getAuthorizationHeaderValue(account),
                      },
                      fadeInDuration: const Duration(),
                      filterQuality: FilterQuality.high,
                      errorWidget: (context, url, error) {
                        // won't work on web because the image is downloaded by
                        // the cache manager instead
                        // where's the preview???
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.white.withOpacity(.8),
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
            if (isFavorite)
              Container(
                // arbitrary size here
                constraints: BoxConstraints.tight(const Size(128, 128)),
                alignment: AlignmentDirectional.bottomStart,
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.star,
                  size: 20,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  final Account account;
  final String? previewUrl;
  final bool isGif;
  final EdgeInsetsGeometry padding;
  final bool isFavorite;
}

class PhotoListVideo extends StatelessWidget {
  const PhotoListVideo({
    Key? key,
    required this.account,
    required this.previewUrl,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: Stack(
          children: [
            Container(
              // arbitrary size here
              constraints: BoxConstraints.tight(const Size(128, 128)),
              color: AppTheme.getListItemBackgroundColor(context),
              child: CachedNetworkImage(
                cacheManager: ThumbnailCacheManager.inst,
                imageUrl: previewUrl,
                httpHeaders: {
                  "Authorization": Api.getAuthorizationHeaderValue(account),
                },
                fadeInDuration: const Duration(),
                filterQuality: FilterQuality.high,
                errorWidget: (context, url, error) {
                  // no preview for this video. Normal since video preview is disabled
                  // by default
                  return Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.white.withOpacity(.8),
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
            if (isFavorite)
              Container(
                // arbitrary size here
                constraints: BoxConstraints.tight(const Size(128, 128)),
                alignment: AlignmentDirectional.bottomStart,
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.star,
                  size: 20,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  final Account account;
  final String previewUrl;
  final bool isFavorite;
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
            icon: const Icon(Icons.edit),
            tooltip: L10n.global().editTooltip,
            onPressed: onEditPressed,
          ),
        ),
      ],
    );
  }

  final VoidCallback? onEditPressed;
}

class PhotoListDate extends StatelessWidget {
  const PhotoListDate({
    Key? key,
    required this.date,
    this.isMonthOnly = false,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    final pattern =
        isMonthOnly ? DateFormat.YEAR_MONTH : DateFormat.YEAR_MONTH_DAY;
    final subtitle =
        DateFormat(pattern, Localizations.localeOf(context).languageCode)
            .format(date.toLocal());
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.caption!.copyWith(
                color: AppTheme.getPrimaryTextColor(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  final DateTime date;
  final bool isMonthOnly;
}
