import 'package:device_info_plus/device_info_plus.dart';

/// System info for Android
///
/// Only meaningful when running on Android. Must call [init] before accessing
/// the data fields
class AndroidInfo {
  factory AndroidInfo() => _inst;

  AndroidInfo._({
    required this.sdkInt,
  });

  static Future<void> init() async {
    final info = await DeviceInfoPlugin().androidInfo;
    final sdkInt = info.version.sdkInt!;

    _inst = AndroidInfo._(
      sdkInt: sdkInt,
    );
  }

  static late final AndroidInfo _inst;

  /// Corresponding to Build.VERSION.SDK_INT
  final int sdkInt;
}

abstract class AndroidVersion {
  static const O = 26;
  // ignore: constant_identifier_names
  static const O_MR1 = 27;
  static const P = 28;
  static const Q = 29;
  static const R = 30;
  static const S = 31;
}
