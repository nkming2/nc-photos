import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

class Logcat {
  static Future<String> dump() async {
    return await _methodChannel.invokeMethod("dump");
  }

  static const _methodChannel = MethodChannel("${k.libId}/logcat_method");
}
