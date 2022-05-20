import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

class ImageProcessor {
  static Future<void> zeroDce(
    String fileUrl,
    String filename,
    int maxWidth,
    int maxHeight,
    int iteration, {
    Map<String, String>? headers,
  }) =>
      _methodChannel.invokeMethod("zeroDce", <String, dynamic>{
        "fileUrl": fileUrl,
        "headers": headers,
        "filename": filename,
        "maxWidth": maxWidth,
        "maxHeight": maxHeight,
        "iteration": iteration,
      });

  static Future<void> deepLab3Portrait(
    String fileUrl,
    String filename,
    int maxWidth,
    int maxHeight,
    int radius, {
    Map<String, String>? headers,
  }) =>
      _methodChannel.invokeMethod("deepLab3Portrait", <String, dynamic>{
        "fileUrl": fileUrl,
        "headers": headers,
        "filename": filename,
        "maxWidth": maxWidth,
        "maxHeight": maxHeight,
        "radius": radius,
      });

  static Future<void> esrgan(
    String fileUrl,
    String filename,
    int maxWidth,
    int maxHeight, {
    Map<String, String>? headers,
  }) =>
      _methodChannel.invokeMethod("esrgan", <String, dynamic>{
        "fileUrl": fileUrl,
        "headers": headers,
        "filename": filename,
        "maxWidth": maxWidth,
        "maxHeight": maxHeight,
      });

  static const _methodChannel =
      MethodChannel("${k.libId}/image_processor_method");
}
