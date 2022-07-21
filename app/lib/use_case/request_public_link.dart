import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/type.dart';

class RequestPublicLink {
  /// Request a temporary unique public link to [file]
  Future<String> call(Account account, File file) async {
    final response =
        await Api(account).ocs().dav().direct().post(fileId: file.fileId!);
    if (!response.isGood) {
      _log.severe("[call] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }
    final JsonObj json = jsonDecode(response.body)["ocs"];
    if (json["meta"]["statuscode"] != 200) {
      _log.shout(
          "[call] Failed requesting server: ${jsonEncode(json["meta"])}");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${json["meta"]["statuscode"]} ${json["meta"]["message"]}");
    }
    return json["data"]["url"];
  }

  static final _log = Logger("use_case.request_public_link.RequestPublicLink");
}
