import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;

Future<bool> isWifi() async {
  if (platform_k.isWeb) {
    // connectivity does NOT work on web, currently it will always return mobile
    // on Blink, and none on Gecko
    return true;
  }
  final result = await Connectivity().checkConnectivity();
  return result == ConnectivityResult.wifi;
}
