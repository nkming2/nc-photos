import 'dart:async';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

class Preference {
  static Future<void> setBool(String prefName, String key, bool value) =>
      _methodChannel.invokeMethod("setBool", {
        "prefName": prefName,
        "key": key,
        "value": value,
      });

  static Future<bool?> getBool(String prefName, String key, [bool? defValue]) =>
      _methodChannel.invokeMethod("getBool", {
        "prefName": prefName,
        "key": key,
        "defValue": defValue,
      });

  static const _methodChannel = MethodChannel("${k.libId}/preference_method");
}
