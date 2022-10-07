/// Helper functions working with remote Nextcloud server
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

/// Return the preview image URL for [fileId]. See [getFilePreviewUrlRelative]
String getFilePreviewUrlByFileId(
  Account account,
  int fileId, {
  required int width,
  required int height,
  String? mode,
  bool? a,
}) {
  String url = "${account.url}/index.php/core/preview?fileId=$fileId";
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

/// Initiate a login with Nextclouds login flow v2: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/index.html#login-flow-v2
Future<InitiateLoginResponse> initiateLogin(Uri uri) async {
  final response = await Api.fromBaseUrl(uri).request(
    "POST",
    "index.php/login/v2",
    header: {
      "User-Agent": "nc-photos",
    },
  );
  if (response.isGood) {
    return InitiateLoginResponse.fromJsonString(response.body);
  } else {
    _log.severe(
        "[initiateLogin] Failed while requesting app password: $response");
    throw ApiException(
        response: response,
        message: "Server responded with an error: HTTP ${response.statusCode}");
  }
}

/// Retrieve App Password after successful initiation of login with Nextclouds login flow v2: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/index.html#login-flow-v2
Future<AppPasswordResponse> _getAppPassword(
    InitiateLoginPollOptions options) async {
  Uri baseUrl;
  if (options.endpoint.scheme == "http") {
    baseUrl = Uri.http(options.endpoint.authority);
  } else {
    baseUrl = Uri.https(options.endpoint.authority);
  }
  final response = await Api.fromBaseUrl(baseUrl).request(
      "POST", options.endpoint.pathSegments.join("/"),
      header: {
        "User-Agent": "nc-photos",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: "token=${options.token}");
  if (response.statusCode == 200) {
    return AppPasswordSuccess.fromJsonString(response.body);
  } else if (response.statusCode == 404) {
    return AppPasswordPending();
  } else {
    _log.severe(
        "[getAppPassword] Failed while requesting app password: $response");
    throw ApiException(
        response: response,
        message: "Server responded with an error: HTTP ${response.statusCode}");
  }
}

/// Polls the app password endpoint every 5 seconds as lang as the token is valid (currently fixed to 20 min)
/// See https://docs.nextcloud.com/server/latest/developer_manual/client_apis/LoginFlow/index.html#login-flow-v2
Stream<Future<AppPasswordResponse>> pollAppPassword(
    InitiateLoginPollOptions options) {
  return Stream.periodic(
          const Duration(seconds: 5), (_) => _getAppPassword(options))
      .takeWhile((_) => options.isTokenValid());
}

class InitiateLoginResponse {
  InitiateLoginResponse.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    poll = InitiateLoginPollOptions(
        json['poll']['token'], json['poll']['endpoint']);
    login = json['login'];
  }

  @override
  toString() {
    return "$runtimeType {"
        "poll: $poll, "
        "login: $login, "
        "}";
  }

  late InitiateLoginPollOptions poll;
  late String login;
}

class InitiateLoginPollOptions {
  InitiateLoginPollOptions(this.token, String endpoint)
      : endpoint = Uri.parse(endpoint),
        _validUntil = DateTime.now().add(const Duration(minutes: 20));

  @override
  toString() {
    return "$runtimeType {"
        "token: ${kDebugMode ? token : '***'}, "
        "endpoint: $endpoint, "
        "}";
  }

  bool isTokenValid() {
    return DateTime.now().isBefore(_validUntil);
  }

  final String token;
  final Uri endpoint;
  final DateTime _validUntil;
}

abstract class AppPasswordResponse {}

class AppPasswordSuccess implements AppPasswordResponse {
  AppPasswordSuccess.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    server = Uri.parse(json['server']);
    loginName = json['loginName'];
    appPassword = json['appPassword'];
  }

  @override
  toString() {
    return "$runtimeType {"
        "server: $server, "
        "loginName: $loginName, "
        "appPassword: ${kDebugMode ? appPassword : '***'}, "
        "}";
  }

  late Uri server;
  late String loginName;
  late String appPassword;
}

class AppPasswordPending implements AppPasswordResponse {}

final _log = Logger("api.api_util");
