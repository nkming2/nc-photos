import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/np_api_util.dart';

/// A square thumbnail widget for a file
class NetworkRectThumbnail extends StatelessWidget {
  const NetworkRectThumbnail({
    super.key,
    required this.account,
    required this.imageUrl,
    this.dimension,
    required this.errorBuilder,
  });

  static String imageUrlForFile(Account account, FileDescriptor file) =>
      api_util.getFilePreviewUrl(
        account,
        file,
        width: k.photoThumbSize,
        height: k.photoThumbSize,
        isKeepAspectRatio: true,
      );

  static String imageUrlForFileId(Account account, int fileId) =>
      api_util.getFilePreviewUrlByFileId(
        account,
        fileId,
        width: k.photoThumbSize,
        height: k.photoThumbSize,
        isKeepAspectRatio: true,
      );

  @override
  Widget build(BuildContext context) {
    final child = FittedBox(
      clipBehavior: Clip.hardEdge,
      fit: BoxFit.cover,
      child: CachedNetworkImage(
        cacheManager: ThumbnailCacheManager.inst,
        imageUrl: imageUrl,
        // imageUrl: "",
        httpHeaders: {
          "Authorization": AuthUtil.fromAccount(account).toHeaderValue(),
        },
        fadeInDuration: const Duration(),
        filterQuality: FilterQuality.high,
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        errorWidget: (context, __, ___) => SizedBox.square(
          dimension: dimension,
          child: errorBuilder(context),
        ),
      ),
    );
    if (dimension != null) {
      return SizedBox.square(
        dimension: dimension,
        child: child,
      );
    } else {
      return AspectRatio(
        aspectRatio: 1,
        child: child,
      );
    }
  }

  final Account account;
  final String imageUrl;
  final double? dimension;
  final Widget Function(BuildContext context) errorBuilder;
}
