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

  ApiFiles files() => ApiFiles(this);
  ApiOcs ocs() => ApiOcs(this);
  ApiSystemtags systemtags() => ApiSystemtags(this);
  ApiSystemtagsRelations systemtagsRelations() => ApiSystemtagsRelations(this);

  static String getAuthorizationHeaderValue(Account account) {
    final auth =
        base64.encode(utf8.encode("${account.username2}:${account.password}"));
    return "Basic $auth";
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
    final splits = _account.address.split("/");
    final authority = splits[0];
    final path = splits.length > 1
        ? splits.sublist(1).join("/") + "/$endpoint"
        : endpoint;
    if (_account.scheme == "http") {
      return Uri.http(authority, path, queryParameters);
    } else {
      return Uri.https(authority, path, queryParameters);
    }
  }

  final Account _account;

  static final _log = Logger("api.api.Api");
}

bool _isHttpStatusGood(int status) => status ~/ 100 == 2;

class ApiFiles {
  ApiFiles(this._api);

  final Api _api;

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
          "Content-Type": mime,
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
    trashbinFilename,
    trashbinOriginalLocation,
    trashbinDeletionTime,
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
      final bool hasNcNs = (hasPreview != null ||
          richWorkspace != null ||
          trashbinFilename != null ||
          trashbinOriginalLocation != null ||
          trashbinDeletionTime != null);
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
            if (trashbinFilename != null) {
              builder.element("nc:trashbin-filename");
            }
            if (trashbinOriginalLocation != null) {
              builder.element("nc:trashbin-original-location");
            }
            if (trashbinDeletionTime != null) {
              builder.element("nc:trashbin-deletion-time");
            }
            for (final p in customProperties ?? []) {
              builder.element(p);
            }
          });
        });
      return await _api.request("PROPFIND", path,
          header: {
            "Content-Type": "application/xml",
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
                  builder.element(e.key, nest: () {
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
                  builder.element(e);
                }
              });
            });
          }
        });
      return await _api.request(
        "PROPPATCH",
        path,
        header: {
          "Content-Type": "application/xml",
        },
        body: builder.buildDocument().toXmlString(),
      );
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
        "Destination": Uri.parse(destinationUrl).toString(),
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
        "Destination": Uri.parse(destinationUrl).toString(),
        if (overwrite != null) "Overwrite": overwrite ? "T" : "F",
      });
    } catch (e) {
      _log.severe("[move] Failed while delete", e);
      rethrow;
    }
  }

  Future<Response> report({
    required String path,
    bool? favorite,
    List<int>? systemtag,
  }) async {
    try {
      final namespaces = <String, String>{
        "DAV:": "d",
        "http://owncloud.org/ns": "oc",
      };
      final builder = XmlBuilder();
      builder
        ..processing("xml", "version=\"1.0\"")
        ..element("oc:filter-files", namespaces: namespaces, nest: () {
          builder.element("oc:filter-rules", nest: () {
            if (favorite != null) {
              builder.element("oc:favorite", nest: () {
                builder.text(favorite ? "1" : "0");
              });
            }
            for (final t in systemtag ?? []) {
              builder.element("oc:systemtag", nest: () {
                builder.text(t);
              });
            }
          });
          builder.element("d:prop", nest: () {
            builder.element("oc:fileid");
          });
        });
      return await _api.request(
        "REPORT",
        path,
        header: {
          "Content-Type": "application/xml",
        },
        body: builder.buildDocument().toXmlString(),
      );
    } catch (e) {
      _log.severe("[report] Failed while report", e);
      rethrow;
    }
  }

  static final _log = Logger("api.api._Files");
}

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

class ApiOcsDavDirect {
  ApiOcsDavDirect(this._dav);

  Future<Response> post({
    required int fileId,
  }) async {
    try {
      return await _dav._ocs._api.request(
        "POST",
        "ocs/v2.php/apps/dav/api/v1/direct",
        header: {
          "OCS-APIRequest": "true",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        queryParameters: {
          "format": "json",
        },
        body: "fileId=$fileId",
      );
    } catch (e) {
      _log.severe("[post] Failed while post", e);
      rethrow;
    }
  }

  final ApiOcsDav _dav;

  static final _log = Logger("api.api._OcsDavDirect");
}

class ApiOcsFacerecognition {
  ApiOcsFacerecognition(this._ocs);

  ApiOcsFacerecognitionPersons persons() => ApiOcsFacerecognitionPersons(this);
  ApiOcsFacerecognitionPerson person(String name) =>
      ApiOcsFacerecognitionPerson(this, name);

  final ApiOcs _ocs;
}

class ApiOcsFacerecognitionPersons {
  ApiOcsFacerecognitionPersons(this._facerecognition);

  Future<Response> get() async {
    try {
      return await _facerecognition._ocs._api.request(
        "GET",
        "ocs/v2.php/apps/facerecognition/api/v1/persons",
        header: {
          "OCS-APIRequest": "true",
        },
        queryParameters: {
          "format": "json",
        },
      );
    } catch (e) {
      _log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  final ApiOcsFacerecognition _facerecognition;

  static final _log = Logger("api.api._OcsFacerecognitionPersons");
}

class ApiOcsFacerecognitionPerson {
  ApiOcsFacerecognitionPerson(this._facerecognition, this._name);

  ApiOcsFacerecognitionPersonFaces faces() =>
      ApiOcsFacerecognitionPersonFaces(this);

  final ApiOcsFacerecognition _facerecognition;
  final String _name;
}

class ApiOcsFacerecognitionPersonFaces {
  ApiOcsFacerecognitionPersonFaces(this._person);

  Future<Response> get() async {
    try {
      return await _person._facerecognition._ocs._api.request(
        "GET",
        "ocs/v2.php/apps/facerecognition/api/v1/person/${_person._name}/faces",
        header: {
          "OCS-APIRequest": "true",
        },
        queryParameters: {
          "format": "json",
        },
      );
    } catch (e) {
      _log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  final ApiOcsFacerecognitionPerson _person;

  static final _log = Logger("api.api._OcsFacerecognitionPersonFaces");
}

class ApiOcsFilesSharing {
  ApiOcsFilesSharing(this._ocs);

  ApiOcsFilesSharingShares shares() => ApiOcsFilesSharingShares(this);
  ApiOcsFilesSharingShare share(String shareId) =>
      ApiOcsFilesSharingShare(this, shareId);
  ApiOcsFilesSharingSharees sharees() => ApiOcsFilesSharingSharees(this);

  final ApiOcs _ocs;
}

class ApiOcsFilesSharingShares {
  ApiOcsFilesSharingShares(this._filesSharing);

  /// Get Shares from a specific file or folder
  ///
  /// If [sharedWithMe] is not null, [subfiles] and [path] are ignored. This is
  /// a limitation of the server API.
  ///
  /// See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/ocs-share-api.html#get-shares-from-a-specific-file-or-folder
  /// See: https://doc.owncloud.com/server/latest/developer_manual/core/apis/ocs-share-api.html#get-all-shares
  Future<Response> get({
    String? path,
    bool? reshares,
    bool? subfiles,
    bool? sharedWithMe,
  }) async {
    try {
      return await _filesSharing._ocs._api.request(
        "GET",
        "ocs/v2.php/apps/files_sharing/api/v1/shares",
        header: {
          "OCS-APIRequest": "true",
        },
        queryParameters: {
          "format": "json",
          if (path != null) "path": path,
          if (reshares != null) "reshares": reshares.toString(),
          if (subfiles != null) "subfiles": subfiles.toString(),
          if (sharedWithMe != null) "shared_with_me": sharedWithMe.toString(),
        },
      );
    } catch (e) {
      _log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  /// Create a new Share
  ///
  /// See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/ocs-share-api.html#create-a-new-share
  Future<Response> post({
    required String path,
    required int shareType,
    String? shareWith,
    String? publicUpload,
    String? password,
    int? permissions,
    String? expireDate,
  }) async {
    try {
      return await _filesSharing._ocs._api.request(
        "POST",
        "ocs/v2.php/apps/files_sharing/api/v1/shares",
        header: {
          "OCS-APIRequest": "true",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        queryParameters: {
          "format": "json",
          "path": path,
          "shareType": shareType.toString(),
          if (shareWith != null) "shareWith": shareWith,
          if (publicUpload != null) "publicUpload": publicUpload,
          if (password != null) "password": password,
          if (password != null) "password": password,
          if (expireDate != null) "expireDate": expireDate.toString(),
        },
      );
    } catch (e) {
      _log.severe("[post] Failed while post", e);
      rethrow;
    }
  }

  final ApiOcsFilesSharing _filesSharing;

  static final _log = Logger("api.api._OcsFilesSharingShares");
}

class ApiOcsFilesSharingShare {
  ApiOcsFilesSharingShare(this._filesSharing, this._shareId);

  /// Remove the given share
  ///
  /// See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/ocs-share-api.html#delete-share
  /// * The type of share ID is listed as int in the document, however, the
  /// share ID returned in [ApiOcsFilesSharingShares.get] is actually a string. To
  /// keep it consistent, we'll use string instead
  Future<Response> delete() async {
    try {
      return await _filesSharing._ocs._api.request(
        "DELETE",
        "ocs/v2.php/apps/files_sharing/api/v1/shares/$_shareId",
        header: {
          "OCS-APIRequest": "true",
        },
      );
    } catch (e) {
      _log.severe("[delete] Failed while delete", e);
      rethrow;
    }
  }

  final ApiOcsFilesSharing _filesSharing;
  final String _shareId;

  static final _log = Logger("api.api._OcsFilesSharingShare");
}

class ApiOcsFilesSharingSharees {
  ApiOcsFilesSharingSharees(this._filesSharing);

  /// Get all sharees matching a search term
  ///
  /// See: https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/ocs-sharee-api.html#search-sharees
  Future<Response> get({
    String? search,
    bool? lookup,
    int? perPage,
    String? itemType,
  }) async {
    try {
      return await _filesSharing._ocs._api.request(
        "GET",
        "ocs/v1.php/apps/files_sharing/api/v1/sharees",
        header: {
          "OCS-APIRequest": "true",
        },
        queryParameters: {
          "format": "json",
          if (search != null) "search": search,
          if (lookup != null) "lookup": lookup.toString(),
          if (perPage != null) "perPage": perPage.toString(),
          if (itemType != null) "itemType": itemType,
        },
      );
    } catch (e) {
      _log.severe("[get] Failed while get", e);
      rethrow;
    }
  }

  final ApiOcsFilesSharing _filesSharing;

  static final _log = Logger("api.api._OcsFilesSharingSharees");
}

class ApiSystemtags {
  const ApiSystemtags(this.api);

  Future<Response> propfind({
    id,
    displayName,
    userVisible,
    userAssignable,
    canAssign,
  }) async {
    const endpoint = "remote.php/dav/systemtags";
    try {
      if (id == null &&
          displayName == null &&
          userVisible == null &&
          userAssignable == null &&
          canAssign == null) {
        // no body
        return await api.request("PROPFIND", endpoint);
      }

      final namespaces = <String, String>{
        "DAV:": "d",
        "http://owncloud.org/ns": "oc",
      };
      final builder = XmlBuilder();
      builder
        ..processing("xml", "version=\"1.0\"")
        ..element("d:propfind", namespaces: namespaces, nest: () {
          builder.element("d:prop", nest: () {
            if (id != null) {
              builder.element("oc:id");
            }
            if (displayName != null) {
              builder.element("oc:display-name");
            }
            if (userVisible != null) {
              builder.element("oc:user-visible");
            }
            if (userAssignable != null) {
              builder.element("oc:user-assignable");
            }
            if (canAssign != null) {
              builder.element("oc:can-assign");
            }
          });
        });
      return await api.request(
        "PROPFIND",
        endpoint,
        header: {
          "Content-Type": "application/xml",
        },
        body: builder.buildDocument().toXmlString(),
      );
    } catch (e) {
      _log.severe("[propfind] Failed while propfind", e);
      rethrow;
    }
  }

  final Api api;

  static final _log = Logger("api.api._Systemtags");
}

class ApiSystemtagsRelations {
  const ApiSystemtagsRelations(this.api);

  ApiSystemtagsRelationsFiles files(int fileId) =>
      ApiSystemtagsRelationsFiles(this, fileId);

  final Api api;
}

class ApiSystemtagsRelationsFiles {
  const ApiSystemtagsRelationsFiles(this.systemtagsRelations, this.fileId);

  /// List systemtags associated with a file
  ///
  /// Warning: this Nextcloud API is undocumented
  Future<Response> propfind({
    id,
    displayName,
    userVisible,
    userAssignable,
    canAssign,
  }) async {
    final endpoint = "remote.php/dav/systemtags-relations/files/$fileId";
    try {
      if (id == null &&
          displayName == null &&
          userVisible == null &&
          userAssignable == null &&
          canAssign == null) {
        // no body
        return await systemtagsRelations.api.request("PROPFIND", endpoint);
      }

      final namespaces = <String, String>{
        "DAV:": "d",
        "http://owncloud.org/ns": "oc",
      };
      final builder = XmlBuilder();
      builder
        ..processing("xml", "version=\"1.0\"")
        ..element("d:propfind", namespaces: namespaces, nest: () {
          builder.element("d:prop", nest: () {
            if (id != null) {
              builder.element("oc:id");
            }
            if (displayName != null) {
              builder.element("oc:display-name");
            }
            if (userVisible != null) {
              builder.element("oc:user-visible");
            }
            if (userAssignable != null) {
              builder.element("oc:user-assignable");
            }
            if (canAssign != null) {
              builder.element("oc:can-assign");
            }
          });
        });
      return await systemtagsRelations.api.request(
        "PROPFIND",
        endpoint,
        header: {
          "Content-Type": "application/xml",
        },
        body: builder.buildDocument().toXmlString(),
      );
    } catch (e) {
      _log.severe("[propfind] Failed while propfind", e);
      rethrow;
    }
  }

  final ApiSystemtagsRelations systemtagsRelations;
  final int fileId;

  static final _log = Logger("api.api._SystemtagsRelationsFiles");
}
