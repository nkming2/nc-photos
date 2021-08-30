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
