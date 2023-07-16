import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/widget/cached_network_image_mod.dart' as mod;

/// A square thumbnail widget for a file
class NetworkRectThumbnail extends StatelessWidget {
  const NetworkRectThumbnail({
    super.key,
    required this.account,
    required this.imageUrl,
    this.dimension,
    required this.errorBuilder,
    this.onSize,
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
      child: mod.CachedNetworkImage(
        cacheManager: ThumbnailCacheManager.inst,
        imageUrl: imageUrl,
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
        imageBuilder: (_, child, __) {
          return _SizeObserver(
            onSize: onSize,
            child: child,
          );
        },
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
  final ValueChanged<Size>? onSize;
}

class _SizeObserver extends SingleChildRenderObjectWidget {
  const _SizeObserver({
    super.child,
    this.onSize,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSizeChangedWithCallback(
      onLayoutChangedCallback: () {
        if (onSize != null) {
          final size = context.findRenderObject()?.as<RenderBox>()?.size;
          if (size != null) {
            onSize?.call(size);
          }
        }
      },
    );
  }

  final ValueChanged<Size>? onSize;
}

class _RenderSizeChangedWithCallback extends RenderProxyBox {
  _RenderSizeChangedWithCallback({
    RenderBox? child,
    required this.onLayoutChangedCallback,
  }) : super(child);

  @override
  void performLayout() {
    super.performLayout();
    if (size != _oldSize) {
      onLayoutChangedCallback();
    }
    _oldSize = size;
  }

  final VoidCallback onLayoutChangedCallback;

  Size? _oldSize;
}
