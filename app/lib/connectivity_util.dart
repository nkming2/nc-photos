import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:np_platform_util/np_platform_util.dart';

Future<bool> isWifi() async {
  if (getRawPlatform() == NpPlatform.web) {
    // connectivity does NOT work on web, currently it will always return mobile
    // on Blink, and none on Gecko
    return true;
  }
  final result = await Connectivity().checkConnectivity();
  return result == ConnectivityResult.wifi;
}
