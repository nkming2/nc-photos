import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:np_ffi_torch/src/np_ffi_torch_bindings_generated.dart' as ffi;
import 'package:np_platform_raw_image/np_platform_raw_image.dart';

extension Rgb8ImageExtension on Rgb8Image {
  Future<T> useNative<T>(
    FutureOr<T> Function(Pointer<ffi.TorchRgb8Image> cImg) fn,
  ) async {
    var cPixel = Pointer<Uint8>.fromAddress(0);
    var cImg = Pointer<ffi.TorchRgb8Image>.fromAddress(0);
    try {
      cPixel = calloc.allocate<Uint8>(pixel.length);
      final typed = cPixel.asTypedList(pixel.length);
      typed.setAll(0, pixel);
      cImg = calloc<ffi.TorchRgb8Image>();
      cImg.ref.pixel = cPixel;
      cImg.ref.width = width;
      cImg.ref.height = height;
      return await fn(cImg);
    } catch (e, stackTrace) {
      _log.severe(
        "[useNative] Failed to convert dart image to native",
        e,
        stackTrace,
      );
      rethrow;
    } finally {
      calloc.free(cPixel);
      calloc.free(cImg);
    }
  }
}

extension TorchRgb8ImageExtension on ffi.TorchRgb8Image {
  Rgb8Image toDart() {
    final dPixel = Uint8List(width * height * 3);
    dPixel.setAll(0, pixel.asTypedList(dPixel.length));
    return Rgb8Image(dPixel, width, height);
  }
}

final _log = Logger("np_ffi_torch.rgb8_image");
