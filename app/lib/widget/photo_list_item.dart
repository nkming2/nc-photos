import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/content_uri_image_provider.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/network_thumbnail.dart';
import 'package:nc_photos/widget/selectable_item_stream_list_mixin.dart';
import 'package:to_string/to_string.dart';

part 'photo_list_item.g.dart';

@toString
abstract class PhotoListFileItem extends SelectableItem {
  const PhotoListFileItem({
    required this.fileIndex,
    required this.file,
    required this.shouldShowFavoriteBadge,
  });

  @override
  get isTappable => true;

  @override
  get isSelectable => true;

  @override
  operator ==(Object other) =>
      other is PhotoListFileItem && file.compareServerIdentity(other.file);

  @override
  get hashCode => file.fdPath.hashCode;

  @override
  String toString() => _$toString();

  final int fileIndex;
  final FileDescriptor file;
  final bool shouldShowFavoriteBadge;
}

class PhotoListImageItem extends PhotoListFileItem {
  const PhotoListImageItem({
    required int fileIndex,
    required FileDescriptor file,
    required this.account,
    required this.previewUrl,
    required bool shouldShowFavoriteBadge,
  }) : super(
          fileIndex: fileIndex,
          file: file,
          shouldShowFavoriteBadge: shouldShowFavoriteBadge,
        );

  @override
  Widget buildWidget(BuildContext context) => PhotoListImage(
        account: account,
        previewUrl: previewUrl,
        isGif: file.fdMime == "image/gif",
        isFavorite: shouldShowFavoriteBadge && file.fdIsFavorite == true,
      );

  final Account account;
  final String previewUrl;
}

class PhotoListVideoItem extends PhotoListFileItem {
  const PhotoListVideoItem({
    required int fileIndex,
    required FileDescriptor file,
    required this.account,
    required this.previewUrl,
    required bool shouldShowFavoriteBadge,
  }) : super(
          fileIndex: fileIndex,
          file: file,
          shouldShowFavoriteBadge: shouldShowFavoriteBadge,
        );

  @override
  buildWidget(BuildContext context) => PhotoListVideo(
        account: account,
        previewUrl: previewUrl,
        isFavorite: shouldShowFavoriteBadge && file.fdIsFavorite == true,
      );

  final Account account;
  final String previewUrl;
}

class PhotoListDateItem extends SelectableItem {
  const PhotoListDateItem({
    required this.date,
    this.isMonthOnly = false,
  });

  @override
  get isTappable => false;

  @override
  get isSelectable => false;

  @override
  get staggeredTile => const StaggeredTile.extent(99, 32);

  @override
  buildWidget(BuildContext context) => PhotoListDate(
        date: date,
        isMonthOnly: isMonthOnly,
      );

  final DateTime date;
  final bool isMonthOnly;
}

abstract class PhotoListLocalFileItem extends SelectableItem {
  const PhotoListLocalFileItem({
    required this.fileIndex,
    required this.file,
  });

  @override
  get isTappable => true;

  @override
  get isSelectable => true;

  @override
  operator ==(Object other) =>
      other is PhotoListLocalFileItem && file.compareIdentity(other.file);

  @override
  get hashCode => file.identityHashCode;

  final int fileIndex;
  final LocalFile file;
}

class PhotoListLocalImageItem extends PhotoListLocalFileItem {
  const PhotoListLocalImageItem({
    required int fileIndex,
    required LocalFile file,
  }) : super(
          fileIndex: fileIndex,
          file: file,
        );

  @override
  buildWidget(BuildContext context) {
    final ImageProvider provider;
    if (file is LocalUriFile) {
      provider = ContentUriImage((file as LocalUriFile).uri);
    } else {
      throw ArgumentError("Invalid file");
    }

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
              color: Theme.of(context).listPlaceholderBackgroundColor,
              child: Image(
                image: ResizeImage.resizeIfNeeded(
                    k.photoThumbSize, null, provider),
                filterQuality: FilterQuality.high,
                fit: BoxFit.cover,
                errorBuilder: (context, e, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Theme.of(context).listPlaceholderForegroundColor,
                    ),
                  );
                },
              ),
            ),
            Container(
              // arbitrary size here
              constraints: BoxConstraints.tight(const Size(128, 128)),
              alignment: AlignmentDirectional.bottomEnd,
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.cloud_off,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoListImage extends StatelessWidget {
  const PhotoListImage({
    Key? key,
    required this.account,
    required this.previewUrl,
    this.padding = const EdgeInsets.all(2),
    this.isGif = false,
    this.isFavorite = false,
    this.heroKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buildPlaceholder() => Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.image_not_supported,
            color: Theme.of(context).listPlaceholderForegroundColor,
          ),
        );
    Widget child;
    if (previewUrl == null) {
      child = FittedBox(
        child: buildPlaceholder(),
      );
    } else {
      child = NetworkRectThumbnail(
        account: account,
        imageUrl: previewUrl!,
        errorBuilder: (_) => buildPlaceholder(),
      );
      if (heroKey != null) {
        child = Hero(
          tag: heroKey!,
          child: child,
        );
      }
    }

    return IconTheme(
      data: const IconThemeData(color: Colors.white),
      child: Padding(
        padding: padding,
        child: Stack(
          children: [
            Container(
              color: Theme.of(context).listPlaceholderBackgroundColor,
              child: child,
            ),
            if (isGif)
              Container(
                alignment: AlignmentDirectional.topEnd,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: const Icon(Icons.gif, size: 26),
              ),
            if (isFavorite)
              Container(
                alignment: AlignmentDirectional.bottomStart,
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.star, size: 15),
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
  // if not null, the image will be contained by a Hero widget
  final String? heroKey;
}

class PhotoListVideo extends StatelessWidget {
  const PhotoListVideo({
    Key? key,
    required this.account,
    required this.previewUrl,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: const IconThemeData(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Stack(
          children: [
            Container(
              color: Theme.of(context).listPlaceholderBackgroundColor,
              child: NetworkRectThumbnail(
                account: account,
                imageUrl: previewUrl,
                errorBuilder: (_) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.image_not_supported,
                    color: Theme.of(context).listPlaceholderForegroundColor,
                  ),
                ),
              ),
            ),
            Container(
              alignment: AlignmentDirectional.topEnd,
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.play_circle_outlined, size: 17),
            ),
            if (isFavorite)
              Container(
                alignment: AlignmentDirectional.bottomStart,
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.star, size: 15),
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
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  final DateTime date;
  final bool isMonthOnly;
}
