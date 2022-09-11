import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/image.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

enum ImageLoaderResizeMethod {
  fit,
  fill,
}

class ImageLoader {
  static Future<Rgba8Image> loadUri(
    String fileUri,
    int maxWidth,
    int maxHeight,
    ImageLoaderResizeMethod resizeMethod, {
    bool isAllowSwapSide = false,
    bool shouldUpscale = false,
    bool shouldFixOrientation = false,
  }) async {
    final result =
        await _methodChannel.invokeMethod<Map>("loadUri", <String, dynamic>{
      "fileUri": fileUri,
      "maxWidth": maxWidth,
      "maxHeight": maxHeight,
      "resizeMethod": resizeMethod.index,
      "isAllowSwapSide": isAllowSwapSide,
      "shouldUpscale": shouldUpscale,
      "shouldFixOrientation": shouldFixOrientation,
    });
    return Rgba8Image.fromJson(result!.cast<String, dynamic>());
  }

  static const _methodChannel = MethodChannel("${k.libId}/image_loader_method");
}
