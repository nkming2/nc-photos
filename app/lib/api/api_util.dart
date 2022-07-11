/// Helper functions working with remote Nextcloud server
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception.dart';

/// Characters that are not allowed in filename
const reservedFilenameChars = "<>:\"/\\|?*";

/// Return the preview image URL for [file]. See [getFilePreviewUrlRelative]
String getFilePreviewUrl(
  Account account,
  File file, {
  required int width,
  required int height,
  String? mode,
  bool? a,
}) {
  return "${account.url}/"
      "${getFilePreviewUrlRelative(account, file, width: width, height: height, mode: mode, a: a)}";
}

/// Return the relative preview image URL for [file]. If [a] == true, the
/// preview will maintain the original aspect ratio, otherwise it will be
/// cropped
String getFilePreviewUrlRelative(
  Account account,
  File file, {
  required int width,
  required int height,
  String? mode,
  bool? a,
}) {
  String url;
  if (file_util.isTrash(account, file)) {
    // trashbin does not support preview.png endpoint
    url = "index.php/apps/files_trashbin/preview?fileId=${file.fileId}";
  } else {
    if (file.fileId != null) {
      url = "index.php/core/preview?fileId=${file.fileId}";
    } else {
      final filePath = Uri.encodeQueryComponent(file.strippedPath);
      url = "index.php/core/preview.png?file=$filePath";
    }
  }

  url = "$url&x=$width&y=$height";
  if (mode != null) {
    url = "$url&mode=$mode";
  }
  if (a != null) {
    url = "$url&a=${a ? 1 : 0}";
  }
  return url;
}

String getFileUrl(Account account, File file) {
  return "${account.url}/${getFileUrlRelative(file)}";
}

String getFileUrlRelative(File file) {
  return file.path;
}

String getWebdavRootUrlRelative(Account account) =>
    "remote.php/dav/files/${account.userId}";

String getTrashbinPath(Account account) =>
    "remote.php/dav/trashbin/${account.userId}/trash";

/// Return the face image URL. See [getFacePreviewUrlRelative]
String getFacePreviewUrl(
  Account account,
  int faceId, {
  required int size,
}) {
  return "${account.url}/"
      "${getFacePreviewUrlRelative(account, faceId, size: size)}";
}

/// Return the relative URL of the face image
String getFacePreviewUrlRelative(
  Account account,
  int faceId, {
  required int size,
}) {
  return "index.php/apps/facerecognition/face/$faceId/thumb/$size";
}

/// Query the app password for [account]
Future<String> exchangePassword(Account account) async {
  final response = await Api(account).request(
    "GET",
    "ocs/v2.php/core/getapppassword",
    header: {
      "OCS-APIRequest": "true",
    },
  );
  if (response.isGood) {
    try {
      final appPwdRegex = RegExp(r"<apppassword>(.*)</apppassword>");
      final appPwdMatch = appPwdRegex.firstMatch(response.body);
      return appPwdMatch!.group(1)!;
    } catch (_) {
      // this happens when the address is not the base URL and so Nextcloud
      // returned the login page
      throw InvalidBaseUrlException();
    }
  } else if (response.statusCode == 403) {
    // If the client is authenticated with an app password a 403 will be
    // returned
    _log.info("[exchangePassword] Already an app password");
    return account.password;
  } else {
    _log.severe(
        "[exchangePassword] Failed while requesting app password: $response");
    throw ApiException(
        response: response,
        message: "Failed communicating with server: ${response.statusCode}");
  }
}

final _log = Logger("api.api_util");
