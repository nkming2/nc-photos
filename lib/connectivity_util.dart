import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

Future<void> waitUntilWifi({VoidCallback? onNoWifi}) async {
  while (true) {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.wifi) {
      return;
    }
    onNoWifi?.call();
    await Future.delayed(const Duration(seconds: 5));
  }
}
