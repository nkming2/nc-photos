import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

class ImageProcessor {
  static Future<void> zeroDce(String image, String filename) =>
      _methodChannel.invokeMethod("zeroDce", <String, dynamic>{
        "image": image,
        "filename": filename,
      });

  static const _methodChannel =
      MethodChannel("${k.libId}/image_processor_method");
}
