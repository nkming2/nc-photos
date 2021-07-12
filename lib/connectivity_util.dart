import 'package:connectivity_plus/connectivity_plus.dart';

Future<void> waitUntilWifi() async {
  while (true) {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.wifi) {
      return;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
}
