import 'package:flutter/services.dart';
import 'package:np_async/np_async.dart';

class Activity {
  static Future<String?> consumeInitialRoute() =>
      _methodChannel.invokeMethod("consumeInitialRoute");

  static Future<bool> isNewGMapsRenderer() =>
      _methodChannel.invokeMethod<bool>("isNewGMapsRenderer").notNull();

  static const _methodChannel = MethodChannel("com.nkming.nc_photos/activity");
}
