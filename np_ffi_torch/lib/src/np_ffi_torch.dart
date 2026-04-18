import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:np_ffi_torch/src/image_util.dart';
import 'package:np_platform_raw_image/np_platform_raw_image.dart';

import 'np_ffi_torch_bindings_generated.dart' as ffi;

Future<Rgb8Image?> inferRealEsrgan(
  Rgb8Image input, {
  required String modelPath,
}) {
  final cModelPath = modelPath.toNativeUtf8();
  try {
    return input.useNative((cInput) {
      var result = Pointer<ffi.TorchRgb8Image>.fromAddress(0);
      try {
        result = _bindings.inferRealEsrgan(cInput, cModelPath.cast());
        if (result.address == 0) {
          return null;
        }
        return result.ref.toDart();
      } finally {
        _bindings.torchRgb8ImageFree(result);
      }
    });
  } finally {
    malloc.free(cModelPath);
  }
}

const String _libName = 'np_ffi_torch';

/// The dynamic library in which the symbols for [NpFfiTorchBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final _bindings = ffi.NpFfiTorchBindings(_dylib);
