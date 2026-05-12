import 'dart:io';
import 'dart:isolate';

import 'package:np_common/size.dart';
import 'package:np_ffi_torch/src/method.dart';
import 'package:np_ffi_torch/src/model_downloader.dart';
import 'package:np_ffi_torch/src/np_ffi_torch.dart';
import 'package:np_platform_raw_image/np_platform_raw_image.dart';

class Retouch implements Method {
  @override
  Future<void> prepareResource({
    void Function(double progress)? onProgress,
  }) async {
    await _modelDownloader.download(ModelType.retouch, onProgress: onProgress);
  }

  @override
  Future<void> cleanResource() {
    return _modelDownloader.delete(ModelType.retouch);
  }

  @override
  Future<bool> isResourceReady() {
    return _modelDownloader.isDownloaded(ModelType.retouch);
  }

  @override
  SizeInt getMaxSrcSize() => const SizeInt(2048, 2048);

  @override
  Future<Rgb8Image?> apply(Rgb8Image src) async {
    final modelFile = await ModelDownloader().download(ModelType.retouch);
    return _applyAsync(src, modelFile: modelFile);
  }

  static Future<Rgb8Image?> _applyAsync(
    Rgb8Image src, {
    required File modelFile,
  }) async {
    return Isolate.run(() async {
      return await inferNeurop(src, modelPath: modelFile.path);
    });
  }

  final _modelDownloader = ModelDownloader();
}
