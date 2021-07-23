import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:xml/xml.dart';

class Response {
  Response(this.statusCode, this.headers, this.body);

  bool get isGood => _isHttpStatusGood(statusCode);

  @override
  String toString() {
    return "{"
        "status: $statusCode, "
        "headers: ..., "
        "body: ..., "
        "}";
  }

  final int statusCode;
  final Map<String, String> headers;

  /// Content of the response body, String if isResponseString == true during
  /// request, Uint8List otherwise
  final dynamic body;
}

class Api {
  Api(this._account);

  _Files files() => _Files(this);

  static String getAuthorizationHeaderValue(Account account) {
    final auth =
        base64.encode(utf8.encode("${account.username}:${account.password}"));
    return "Basic $auth";
  }

  Future<Response> request(
    String method,
    String endpoint, {
    Map<String, String>? header,
    String? body,
    Uint8List? bodyBytes,
    bool isResponseString = true,
  }) async {
    final url = _makeUri(endpoint);
    final req = http.Request(method, url)
      ..headers.addAll({
        "authorization": getAuthorizationHeaderValue(_account),
      });
    if (header != null) {
      // turn all to lower case, since HTTP headers are case-insensitive, this
      // smooths our processing (if any)
      req.headers.addEntries(
          header.entries.map((e) => MapEntry(e.key.toLowerCase(), e.value)));
    }
    if (body != null) {
      if (!req.headers.containsKey("content-type")) {
        req.headers["content-type"] = "application/xml";
      }
      req.body = body;
    } else if (bodyBytes != null) {
      if (!req.headers.containsKey("content-type")) {
        req.headers["content-type"] = "application/octet-stream";
      }
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

  Uri _makeUri(String endpoint) {
    final splits = _account.address.split("/");
    final authority = splits[0];
    final path = splits.length > 1
        ? splits.sublist(1).join("/") + "/$endpoint"
        : endpoint;
    if (_account.scheme == "http") {
      return Uri.http(authority, path);
    } else {
      return Uri.https(authority, path);
    }
  }

  final Account _account;

  static final _log = Logger("api.api.Api");
}

bool _isHttpStatusGood(int status) => status ~/ 100 == 2;

class _Files {
  _Files(this._api);

  Api _api;

  Future<Response> delete({
    required String path,
  }) async {
    try {
      return await _api.request("DELETE", path);
    } catch (e) {
      _log.severe("[delete] Failed while delete", e);
      rethrow;
    }
  }

  Future<Response> get({
    required String path,
  }) async {
    try {
      return await _api.request("GET", path, isResponseString: false);
    } catch (e) {
      _log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  Future<Response> put({
    required String path,
    String mime = "application/octet-stream",
    required Uint8List content,
  }) async {
    try {
      return await _api.request(
        "PUT",
        path,
        header: {
          "content-type": mime,
        },
        bodyBytes: content,
      );
    } catch (e) {
      _log.severe("[put] Failed while put", e);
      rethrow;
    }
  }

  Future<Response> propfind({
    required String path,
    int? depth,
    getlastmodified,
    getetag,
    getcontenttype,
    resourcetype,
    getcontentlength,
    id,
    fileid,
    favorite,
    commentsHref,
    commentsCount,
    commentsUnread,
    ownerId,
    ownerDisplayName,
    shareTypes,
    checksums,
    hasPreview,
    size,
    richWorkspace,
    Map<String, String>? customNamespaces,
    List<String>? customProperties,
  }) async {
    try {
      final bool hasDavNs = (getlastmodified != null ||
          getetag != null ||
          getcontenttype != null ||
          resourcetype != null ||
          getcontentlength != null);
      final bool hasOcNs = (id != null ||
          fileid != null ||
          favorite != null ||
          commentsHref != null ||
          commentsCount != null ||
          commentsUnread != null ||
          ownerId != null ||
          ownerDisplayName != null ||
          shareTypes != null ||
          checksums != null ||
          size != null);
      final bool hasNcNs = (hasPreview != null || richWorkspace != null);
      if (!hasDavNs && !hasOcNs && !hasNcNs) {
        // no body
        return await _api.request("PROPFIND", path);
      }

      final namespaces = <String, String>{
        "DAV:": "d",
        if (hasOcNs) "http://owncloud.org/ns": "oc",
        if (hasNcNs) "http://nextcloud.org/ns": "nc",
      }..addAll(customNamespaces ?? {});
      final builder = XmlBuilder();
      builder
        ..processing("xml", "version=\"1.0\"")
        ..element("d:propfind", namespaces: namespaces, nest: () {
          builder.element("d:prop", nest: () {
            if (getlastmodified != null) {
              builder.element("d:getlastmodified");
            }
            if (getetag != null) {
              builder.element("d:getetag");
            }
            if (getcontenttype != null) {
              builder.element("d:getcontenttype");
            }
            if (resourcetype != null) {
              builder.element("d:resourcetype");
            }
            if (getcontentlength != null) {
              builder.element("d:getcontentlength");
            }
            if (id != null) {
              builder.element("oc:id");
            }
            if (fileid != null) {
              builder.element("oc:fileid");
            }
            if (favorite != null) {
              builder.element("oc:favorite");
            }
            if (commentsHref != null) {
              builder.element("oc:comments-href");
            }
            if (commentsCount != null) {
              builder.element("oc:comments-count");
            }
            if (commentsUnread != null) {
              builder.element("oc:comments-unread");
            }
            if (ownerId != null) {
              builder.element("oc:owner-id");
            }
            if (ownerDisplayName != null) {
              builder.element("oc:owner-display-name");
            }
            if (shareTypes != null) {
              builder.element("oc:share-types");
            }
            if (checksums != null) {
              builder.element("oc:checksums");
            }
            if (size != null) {
              builder.element("oc:size");
            }
            if (hasPreview != null) {
              builder.element("nc:has-preview");
            }
            if (richWorkspace != null) {
              builder.element("nc:rich-workspace");
            }
            for (final p in customProperties ?? []) {
              builder.element(p);
            }
          });
        });
      return await _api.request("PROPFIND", path,
          header: {
            if (depth != null) "Depth": depth.toString(),
          },
          body: builder.buildDocument().toXmlString());
    } catch (e) {
      _log.severe("[propfind] Failed while propfind", e);
      rethrow;
    }
  }

  /// Set or remove custom properties
  ///
  /// [namespaces] should be specified in the format {"URI": "prefix"}, eg,
  /// {"DAV:": "d"}
  Future<Response> proppatch({
    required String path,
    Map<String, String>? namespaces,
    Map<String, dynamic>? set,
    List<String>? remove,
  }) async {
    try {
      final ns = <String, String>{
        "DAV:": "d",
      }..addAll(namespaces ?? {});
      final builder = XmlBuilder();
      builder
        ..processing("xml", "version=\"1.0\"")
        ..element("d:propertyupdate", namespaces: ns, nest: () {
          if (set != null && set.isNotEmpty) {
            builder.element("d:set", nest: () {
              builder.element("d:prop", nest: () {
                for (final e in set.entries) {
                  builder.element("${e.key}", nest: () {
                    builder.text("${e.value}");
                  });
                }
              });
            });
          }
          if (remove != null && remove.isNotEmpty) {
            builder.element("d:remove", nest: () {
              builder.element("d:prop", nest: () {
                for (final e in remove) {
                  builder.element("$e");
                }
              });
            });
          }
        });
      return await _api.request("PROPPATCH", path,
          body: builder.buildDocument().toXmlString());
    } catch (e) {
      _log.severe("[proppatch] Failed while proppatch", e);
      rethrow;
    }
  }

  /// A folder can be created by sending a MKCOL request to the folder
  Future<Response> mkcol({
    required String path,
  }) async {
    try {
      return await _api.request("MKCOL", path);
    } catch (e) {
      _log.severe("[mkcol] Failed while get", e);
      rethrow;
    }
  }

  /// A file or folder can be copied by sending a COPY request to the file or
  /// folder and specifying the [destinationUrl] as full url
  Future<Response> copy({
    required String path,
    required String destinationUrl,
    bool? overwrite,
  }) async {
    try {
      return await _api.request("COPY", path, header: {
        "Destination": destinationUrl,
        if (overwrite != null) "Overwrite": overwrite ? "T" : "F",
      });
    } catch (e) {
      _log.severe("[copy] Failed while delete", e);
      rethrow;
    }
  }

  /// A file or folder can be moved by sending a MOVE request to the file or
  /// folder and specifying the [destinationUrl] as full url
  Future<Response> move({
    required String path,
    required String destinationUrl,
    bool? overwrite,
  }) async {
    try {
      return await _api.request("MOVE", path, header: {
        "Destination": destinationUrl,
        if (overwrite != null) "Overwrite": overwrite ? "T" : "F",
      });
    } catch (e) {
      _log.severe("[move] Failed while delete", e);
      rethrow;
    }
  }

  static final _log = Logger("api.api._Files");
}
