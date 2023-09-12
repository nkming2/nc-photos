import 'package:flutter/services.dart';
import 'package:np_async/np_async.dart';
import 'package:np_gps_map/src/k.dart' as k;

class Native {
  static Future<bool> isNewGMapsRenderer() =>
      _methodChannel.invokeMethod<bool>("isNewGMapsRenderer").notNull();

  static const _methodChannel = MethodChannel("${k.libId}/gps_map_method");
}
