import 'dart:async';

import 'package:flutter/services.dart';
import 'package:np_platform_log/src/k.dart' as k;

class PlatformLog {
  /// Get the current native logs
  static Future<String> dump() async {
    return await _methodChannel.invokeMethod("dump");
  }

  static const _methodChannel = MethodChannel("${k.libId}/logcat_method");
}
