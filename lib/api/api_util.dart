/// Helper functions working with remote Nextcloud server
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';

/// Return the preview image URL for [file]. See [getFilePreviewUrlRelative]
String getFilePreviewUrl(
  Account account,
  File file, {
  @required int width,
  @required int height,
  String mode,
  bool a,
}) {
  return "${account.url}/"
      "${getFilePreviewUrlRelative(file, width: width, height: height, mode: mode, a: a)}";
}

/// Return the relative preview image URL for [file]. If [a] == true, the
/// preview will maintain the original aspect ratio, otherwise it will be
/// cropped
String getFilePreviewUrlRelative(
  File file, {
  @required int width,
  @required int height,
  String mode,
  bool a,
}) {
  final filePath = Uri.encodeQueryComponent(file.strippedPath);
  var url = "core/preview.png?file=$filePath&x=$width&y=$height";
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
    "remote.php/dav/files/${account.username}";

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
    final appPwdRegex = RegExp(r"<apppassword>(.*)</apppassword>");
    final appPwdMatch = appPwdRegex.firstMatch(response.body);
    return appPwdMatch.group(1);
  } else if (response.statusCode == 403) {
    // If the client is authenticated with an app password a 403 will be
    // returned
    _log.info("[exchangePassword] Already an app password");
    return account.password;
  } else {
    _log.severe(
        "[exchangePassword] Failed while requesting app password: $response");
    throw HttpException(
        "Failed communicating with server: ${response.statusCode}");
  }
}

final _log = Logger("api.api_util");
