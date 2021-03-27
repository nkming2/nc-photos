import 'package:nc_photos/platform/k.dart' as platform_k;

class AdHelper {
  static String get bannerAdUnitId {
    if (platform_k.isAndroid) {
      return "";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (platform_k.isAndroid) {
      return "";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
