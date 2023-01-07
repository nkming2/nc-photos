import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/string_extension.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';
import 'package:xml/xml.dart';

part 'api.g.dart';
part 'direct_api.dart';
part 'face_recognition_api.dart';
part 'files_api.dart';
part 'files_sharing_api.dart';
part 'systemtag_api.dart';

@toString
class Response {
  Response(this.statusCode, this.headers, this.body);

  bool get isGood => _isHttpStatusGood(statusCode);

  @override
  String toString() => _$toString();

  final int statusCode;
  @Format(r"...")
  final Map<String, String> headers;

  /// Content of the response body, String if isResponseString == true during
  /// request, Uint8List otherwise
  @Format(
      r"${kDebugMode ? body.toString().replaceAll(RegExp(r'\n\t'), '').slice(0, 200) : '...'}")
  final dynamic body;
}

class BasicAuth {
  BasicAuth(this.username, this.password);

  BasicAuth.fromAccount(Account account)
      : this(
          account.username2,
          account.password,
        );

  @override
  toString() {
    final authString = base64.encode(utf8.encode("$username:$password"));
    return "Basic $authString";
  }

  final String username;
  final String password;
}

@npLog
class Api {
  Api(Account account)
      : _baseUrl = Uri.parse(account.url),
        _auth = BasicAuth.fromAccount(account);

  Api.fromBaseUrl(Uri baseUrl) : _baseUrl = baseUrl;

  ApiFiles files() => ApiFiles(this);

  ApiOcs ocs() => ApiOcs(this);

  ApiSystemtags systemtags() => ApiSystemtags(this);

  ApiSystemtagsRelations systemtagsRelations() => ApiSystemtagsRelations(this);

  static String getAuthorizationHeaderValue(Account account) {
    return BasicAuth.fromAccount(account).toString();
  }

  Future<Response> request(
    String method,
    String endpoint, {
    Map<String, String>? header,
    Map<String, String>? queryParameters,
    String? body,
    Uint8List? bodyBytes,
    bool isResponseString = true,
  }) async {
    final url = _makeUri(endpoint, queryParameters: queryParameters);
    final req = http.Request(method, url);
    if (_auth != null) {
      req.headers.addAll({
        "authorization": _auth.toString(),
      });
    }
    if (header != null) {
      // turn all to lower case, since HTTP headers are case-insensitive, this
      // smooths our processing (if any)
      req.headers.addEntries(
          header.entries.map((e) => MapEntry(e.key.toLowerCase(), e.value)));
    }
    if (body != null) {
      req.body = body;
    } else if (bodyBytes != null) {
      req.bodyBytes = bodyBytes;
    }
    final response =
        await http.Response.fromStream(await http.Client().send(req));
    if (!_isHttpStatusGood(response.statusCode)) {
      if (response.statusCode == 404) {
        _log.severe(
          "[request] HTTP $method (${response.statusCode}): $endpoint",
        );
      } else {
        _log.severe(
          "[request] HTTP $method (${response.statusCode}): $endpoint",
          response.body,
        );
      }
    }
    return Response(response.statusCode, response.headers,
        isResponseString ? response.body : response.bodyBytes);
  }

  Uri _makeUri(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) {
    final path = _baseUrl.path + "/$endpoint";
    if (_baseUrl.scheme == "http") {
      return Uri.http(_baseUrl.authority, path, queryParameters);
    } else {
      return Uri.https(_baseUrl.authority, path, queryParameters);
    }
  }

  final Uri _baseUrl;
  BasicAuth? _auth;
}

bool _isHttpStatusGood(int status) => status ~/ 100 == 2;

class ApiOcs {
  ApiOcs(this._api);

  ApiOcsDav dav() => ApiOcsDav(this);

  ApiOcsFacerecognition facerecognition() => ApiOcsFacerecognition(this);

  ApiOcsFilesSharing filesSharing() => ApiOcsFilesSharing(this);

  final Api _api;
}

class ApiOcsDav {
  ApiOcsDav(this._ocs);

  ApiOcsDavDirect direct() => ApiOcsDavDirect(this);

  final ApiOcs _ocs;
}
