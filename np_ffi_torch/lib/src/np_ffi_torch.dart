import 'dart:ffi';
import 'dart:io';
import 'dart:math';

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

Future<Rgb8Image?> inferNafnet(Rgb8Image input, {required String modelPath}) {
  final cModelPath = modelPath.toNativeUtf8();
  try {
    return input.useNative((cInput) {
      var result = Pointer<ffi.TorchRgb8Image>.fromAddress(0);
      try {
        result = _bindings.inferNafnet(cInput, cModelPath.cast());
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

Future<Rgb8Image?> inferEfficientDerain(
  Rgb8Image input, {
  required String modelPath,
}) {
  final cModelPath = modelPath.toNativeUtf8();
  try {
    return input.useNative((cInput) {
      var result = Pointer<ffi.TorchRgb8Image>.fromAddress(0);
      try {
        result = _bindings.inferEfficientDerain(cInput, cModelPath.cast());
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

Future<Rgb8Image?> inferNeurop(Rgb8Image input, {required String modelPath}) {
  final cModelPath = modelPath.toNativeUtf8();
  try {
    return input.useNative((cInput) {
      var result = Pointer<ffi.TorchRgb8Image>.fromAddress(0);
      try {
        result = _bindings.inferNeurop(cInput, cModelPath.cast());
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

Future<Rgb8Image?> inferZeroDce(Rgb8Image input, {required String modelPath}) {
  final cModelPath = modelPath.toNativeUtf8();
  try {
    return input.useNative((cInput) {
      var result = Pointer<ffi.TorchRgb8Image>.fromAddress(0);
      try {
        result = _bindings.inferZeroDce(cInput, cModelPath.cast());
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

Future<Rgba8Image?> inferEfficientSamExtract(
  Rgb8Image input, {
  required List<Point<int>> points,
  required List<int> pointLabels,
  required String modelPath,
}) {
  if (points.length != pointLabels.length || points.length > 6) {
    throw ArgumentError(
      "points and pointLabels must have the same size and <= 6",
    );
  }
  final cModelPath = modelPath.toNativeUtf8();
  final cPoints = malloc.allocate<ffi.TorchPoint>(6 * sizeOf<ffi.TorchPoint>());
  final cPointLabels = malloc.allocate<Int>(6 * sizeOf<Int>());
  try {
    for (var i = 0; i < points.length; ++i) {
      cPoints[i].x = points[i].x;
      cPoints[i].y = points[i].y;
    }
    for (var i = points.length; i < 6; ++i) {
      cPoints[i].x = -1;
      cPoints[i].y = -1;
    }

    for (var i = 0; i < pointLabels.length; ++i) {
      cPointLabels[i] = pointLabels[i];
    }
    for (var i = pointLabels.length; i < 6; ++i) {
      cPointLabels[i] = -1;
    }

    return input.useNative((cInput) {
      var result = Pointer<ffi.TorchRgba8Image>.fromAddress(0);
      try {
        result = _bindings.inferEfficientSamExtract(
          cInput,
          cPoints,
          cPointLabels,
          cModelPath.cast(),
        );
        if (result.address == 0) {
          return null;
        }
        return result.ref.toDart();
      } finally {
        _bindings.torchRgba8ImageFree(result);
      }
    });
  } finally {
    malloc.free(cPointLabels);
    malloc.free(cPoints);
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
