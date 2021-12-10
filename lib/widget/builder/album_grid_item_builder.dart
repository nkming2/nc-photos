import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/album_grid_item.dart';

/// Build a standard [AlbumGridItem] for an [Album]
class AlbumGridItemBuilder {
  AlbumGridItemBuilder({
    required this.account,
    required this.album,
    this.isShared = false,
  });

  AlbumGridItem build(BuildContext context) {
    var subtitle = "";
    String? subtitle2;
    if (album.provider is AlbumStaticProvider) {
      subtitle =
          L10n.global().albumSize(AlbumStaticProvider.of(album).items.length);
    } else if (album.provider is AlbumDirProvider) {
      final provider = album.provider as AlbumDirProvider;
      subtitle = provider.dirs.first.strippedPath;
      if (provider.dirs.length > 1) {
        subtitle2 = "+${provider.dirs.length - 1}";
      }
    }
    if (isShared) {
      subtitle = "${L10n.global().albumSharedLabel} | $subtitle";
    }
    return AlbumGridItem(
      cover: _buildAlbumCover(context, album),
      title: album.name,
      subtitle: subtitle,
      subtitle2: subtitle2,
      icon: album.provider is AlbumDirProvider ? Icons.folder : null,
    );
  }

  Widget _buildAlbumCover(BuildContext context, Album album) {
    Widget cover;
    try {
      final coverFile = album.coverProvider.getCover(album);
      final previewUrl = api_util.getFilePreviewUrl(account, coverFile!,
          width: k.coverSize, height: k.coverSize);
      cover = FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: CachedNetworkImage(
          cacheManager: CoverCacheManager.inst,
          imageUrl: previewUrl,
          httpHeaders: {
            "Authorization": Api.getAuthorizationHeaderValue(account),
          },
          fadeInDuration: const Duration(),
          filterQuality: FilterQuality.high,
          errorWidget: (context, url, error) {
            // just leave it empty
            return Container();
          },
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        ),
      );
    } catch (_) {
      cover = Icon(
        Icons.panorama,
        color: Colors.white.withOpacity(.8),
        size: 88,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: AppTheme.getListItemBackgroundColor(context),
        constraints: const BoxConstraints.expand(),
        child: cover,
      ),
    );
  }

  final Account account;
  final Album album;
  final bool isShared;
}
