import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/image.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

abstract class ImageFilter {
  Map<String, dynamic> toJson();
}

class ColorBrightnessFilter extends _SingleWeightFilter {
  const ColorBrightnessFilter(double weight) : super("brightness", weight);
}

class ColorContrastFilter extends _SingleWeightFilter {
  const ColorContrastFilter(double weight) : super("contrast", weight);
}

class ColorWhitePointFilter extends _SingleWeightFilter {
  const ColorWhitePointFilter(double weight) : super("whitePoint", weight);
}

class ColorHighlightFilter extends _SingleWeightFilter {
  const ColorHighlightFilter(double weight) : super("highlight", weight);
}

class ColorShadowFilter extends _SingleWeightFilter {
  const ColorShadowFilter(double weight) : super("shadow", weight);
}

class ColorBlackPointFilter extends _SingleWeightFilter {
  const ColorBlackPointFilter(double weight) : super("blackPoint", weight);
}

class ColorSaturationFilter extends _SingleWeightFilter {
  const ColorSaturationFilter(double weight) : super("saturation", weight);
}

class ColorWarmthFilter extends _SingleWeightFilter {
  const ColorWarmthFilter(double weight) : super("warmth", weight);
}

class ColorTintFilter extends _SingleWeightFilter {
  const ColorTintFilter(double weight) : super("tint", weight);
}

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

  static Future<void> arbitraryStyleTransfer(
    String fileUrl,
    String filename,
    int maxWidth,
    int maxHeight,
    String styleUri,
    double weight, {
    Map<String, String>? headers,
  }) =>
      _methodChannel.invokeMethod("arbitraryStyleTransfer", <String, dynamic>{
        "fileUrl": fileUrl,
        "headers": headers,
        "filename": filename,
        "maxWidth": maxWidth,
        "maxHeight": maxHeight,
        "styleUri": styleUri,
        "weight": weight,
      });

  static Future<void> filter(
    String fileUrl,
    String filename,
    int maxWidth,
    int maxHeight,
    List<ImageFilter> filters, {
    Map<String, String>? headers,
  }) =>
      _methodChannel.invokeMethod("filter", <String, dynamic>{
        "fileUrl": fileUrl,
        "headers": headers,
        "filename": filename,
        "maxWidth": maxWidth,
        "maxHeight": maxHeight,
        "filters": filters.map((f) => f.toJson()).toList(),
      });

  static Future<Rgba8Image> filterPreview(
    Rgba8Image img,
    List<ImageFilter> filters,
  ) async {
    final result = await _methodChannel
        .invokeMethod<Map>("filterPreview", <String, dynamic>{
      "rgba8": img.toJson(),
      "filters": filters.map((f) => f.toJson()).toList(),
    });
    return Rgba8Image.fromJson(result!.cast<String, dynamic>());
  }

  static const _methodChannel =
      MethodChannel("${k.libId}/image_processor_method");
}

class _SingleWeightFilter implements ImageFilter {
  const _SingleWeightFilter(this.type, this.weight);

  @override
  toJson() => {
        "type": type,
        "weight": weight,
      };

  final String type;
  final double weight;
}
