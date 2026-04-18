import 'dart:ffi';
import 'dart:io';

import 'np_ffi_torch_bindings_generated.dart';

int getCoresCount() {
  return _bindings.getCoresCount();
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
final NpFfiTorchBindings _bindings = NpFfiTorchBindings(_dylib);
