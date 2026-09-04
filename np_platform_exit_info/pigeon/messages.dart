import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: "lib/src/messages.g.dart",
    dartPackageName: "np_platform_exit_info",
    kotlinOut:
        'android/src/main/kotlin/com/nkming/nc_photos/np_platform_exit_info/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: "com.nkming.nc_photos.np_platform_exit_info",
    ),
  ),
)
// see https://developer.android.com/reference/android/app/ApplicationExitInfo
class ExitInfo {
  late final String? description;
  late final int pss;
  late final int reason;
  late final int rss;
  late final int status;
  late final int timestamp;
}

@HostApi()
abstract class MyHostApi {
  @async
  ExitInfo? getExifInfo();
}
