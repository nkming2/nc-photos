import 'package:logging/logging.dart';
import 'package:nc_photos/stream_extension.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

Future<Map<String, int>> requestPermissionsForResult(
    List<String> permissions) async {
  Map<String, int>? result;
  final resultFuture = Permission.stream
      .whereType<PermissionRequestResult>()
      .first
      .then((ev) => result = ev.grantResults);
  await Permission.request(permissions);
  await resultFuture;
  _log.info("[requestPermissionsForResult] Result: $result");
  return result!;
}

final _log = Logger("mobile.android.permission_util");
