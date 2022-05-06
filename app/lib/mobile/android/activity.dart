import 'package:flutter/services.dart';

class Activity {
  static Future<String?> consumeInitialRoute() =>
      _methodChannel.invokeMethod("consumeInitialRoute");

  static const _methodChannel = MethodChannel("com.nkming.nc_photos/activity");
}
