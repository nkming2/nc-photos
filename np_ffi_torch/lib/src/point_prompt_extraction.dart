import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:np_common/size.dart';
import 'package:np_ffi_torch/src/method.dart';
import 'package:np_ffi_torch/src/model_downloader.dart';
import 'package:np_ffi_torch/src/np_ffi_torch.dart';
import 'package:np_log/np_log.dart';
import 'package:np_platform_raw_image/np_platform_raw_image.dart';

part 'point_prompt_extraction.g.dart';

/// Extract part of an image (making other part transparent) with point prompts
@npLog
class PointPromptExtraction implements Method {
  @override
  Future<void> prepareResource({
    void Function(double progress, int size)? onProgress,
  }) async {
    await _modelDownloader.download(
      ModelType.pointPromptSegmentation,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> cleanResource() {
    return _modelDownloader.delete(ModelType.pointPromptSegmentation);
  }

  @override
  Future<bool> isResourceReady() {
    return _modelDownloader.isDownloaded(ModelType.pointPromptSegmentation);
  }

  @override
  SizeInt getMaxSrcSize() => const SizeInt(1024, 1024);

  Future<Rgba8Image?> apply(
    Rgb8Image src, {
    required List<Point<int>> points,
    required List<int> pointLabels,
  }) async {
    _log.info("[apply] points: $points");
    final modelFile = await ModelDownloader().download(
      ModelType.pointPromptSegmentation,
    );
    return _applyAsync(
      src,
      points: points,
      pointLabels: pointLabels,
      modelFile: modelFile,
    );
  }

  static Future<Rgba8Image?> _applyAsync(
    Rgb8Image src, {
    required List<Point<int>> points,
    required List<int> pointLabels,
    required File modelFile,
  }) async {
    return Isolate.run(() async {
      return await inferEfficientSamExtract(
        src,
        points: points,
        pointLabels: pointLabels,
        modelPath: modelFile.path,
      );
    });
  }

  final _modelDownloader = ModelDownloader();
}
