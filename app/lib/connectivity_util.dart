import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:nc_photos/async_util.dart' as async_util;
import 'package:nc_photos/platform/k.dart' as platform_k;

Future<void> waitUntilWifi({VoidCallback? onNoWifi}) async {
  if (platform_k.isWeb) {
    // connectivity does NOT work on web, currently it will always return mobile
    // on Blink, and none on Gecko
    return;
  }
  await async_util.wait(
    () async {
      final result = await Connectivity().checkConnectivity();
      if (result == ConnectivityResult.wifi) {
        return true;
      }
      onNoWifi?.call();
      return false;
    },
    pollInterval: const Duration(seconds: 5),
  );
}
