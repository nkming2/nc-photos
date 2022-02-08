import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/string_extension.dart';
import 'package:xml/xml.dart';

class WebdavResponseParser {
  List<File> parseFiles(XmlDocument xml) => _parse<File>(xml, _toFile);

  List<Favorite> parseFavorites(XmlDocument xml) =>
      _parse<Favorite>(xml, _toFavorite);

  Map<String, String> get namespaces => _namespaces;

  List<T> _parse<T>(XmlDocument xml, T Function(XmlElement) mapper) {
    _namespaces = _parseNamespaces(xml);
    final body = () {
      try {
        return xml.children.whereType<XmlElement>().firstWhere((element) =>
            element.matchQualifiedName("multistatus",
                prefix: "DAV:", namespaces: _namespaces));
      } catch (_) {
        _log.shout("[_parse] Missing element: multistatus");
        rethrow;
      }
    }();
    return body.children
        .whereType<XmlElement>()
        .where((e) => e.matchQualifiedName("response",
            prefix: "DAV:", namespaces: _namespaces))
        .map((e) {
          try {
            return mapper(e);
          } catch (e, stackTrace) {
            _log.shout("[_parse] Failed parsing XML", e, stackTrace);
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }

  Map<String, String> _parseNamespaces(XmlDocument xml) {
    final namespaces = <String, String>{};
    final xmlContent = xml.descendants.whereType<XmlElement>().firstWhere(
        (element) => !element.name.qualified.startsWith("?"),
        orElse: () => XmlElement(XmlName.fromString("")));
    for (final a in xmlContent.attributes) {
      if (a.name.prefix == "xmlns") {
        namespaces[a.name.local] = a.value;
      } else if (a.name.local == "xmlns") {
        namespaces["!"] = a.value;
      }
    }
    // _log.fine("[_parseNamespaces] Namespaces: $namespaces");
    return namespaces;
  }

  /// Map <DAV:response> contents to File
  File _toFile(XmlElement element) {
    String? path;
    int? contentLength;
    String? contentType;
    String? etag;
    DateTime? lastModified;
    bool? isCollection;
    int? usedBytes;
    bool? hasPreview;
    int? fileId;
    bool? isFavorite;
    CiString? ownerId;
    Metadata? metadata;
    bool? isArchived;
    DateTime? overrideDateTime;
    String? trashbinFilename;
    String? trashbinOriginalLocation;
    DateTime? trashbinDeletionTime;

    for (final child in element.children.whereType<XmlElement>()) {
      if (child.matchQualifiedName("href",
          prefix: "DAV:", namespaces: _namespaces)) {
        path = _hrefToPath(child);
      } else if (child.matchQualifiedName("propstat",
          prefix: "DAV:", namespaces: _namespaces)) {
        final status = child.children
            .whereType<XmlElement>()
            .firstWhere((element) => element.matchQualifiedName("status",
                prefix: "DAV:", namespaces: _namespaces))
            .innerText;
        if (!status.contains(" 200 ")) {
          continue;
        }
        final prop = child.children.whereType<XmlElement>().firstWhere(
            (element) => element.matchQualifiedName("prop",
                prefix: "DAV:", namespaces: _namespaces));
        final propParser =
            _FilePropParser(namespaces: _namespaces, logFilePath: path);
        propParser.parse(prop);
        contentLength = propParser.contentLength;
        contentType = propParser.contentType;
        etag = propParser.etag;
        lastModified = propParser.lastModified;
        isCollection = propParser.isCollection;
        usedBytes = propParser.usedBytes;
        hasPreview = propParser.hasPreview;
        fileId = propParser.fileId;
        isFavorite = propParser.isFavorite;
        ownerId = propParser.ownerId;
        metadata = propParser.metadata;
        isArchived = propParser.isArchived;
        overrideDateTime = propParser.overrideDateTime;
        trashbinFilename = propParser.trashbinFilename;
        trashbinOriginalLocation = propParser.trashbinOriginalLocation;
        trashbinDeletionTime = propParser.trashbinDeletionTime;
      }
    }

    return File(
      path: path!,
      contentLength: contentLength,
      contentType: contentType,
      etag: etag,
      lastModified: lastModified,
      isCollection: isCollection,
      usedBytes: usedBytes,
      hasPreview: hasPreview,
      fileId: fileId,
      isFavorite: isFavorite,
      ownerId: ownerId,
      metadata: metadata,
      isArchived: isArchived,
      overrideDateTime: overrideDateTime,
      trashbinFilename: trashbinFilename,
      trashbinOriginalLocation: trashbinOriginalLocation,
      trashbinDeletionTime: trashbinDeletionTime,
    );
  }

  /// Map <DAV:response> contents to Favorite
  Favorite _toFavorite(XmlElement element) {
    String? path;
    int? fileId;

    for (final child in element.children.whereType<XmlElement>()) {
      if (child.matchQualifiedName("href",
          prefix: "DAV:", namespaces: _namespaces)) {
        path = _hrefToPath(child);
      } else if (child.matchQualifiedName("propstat",
          prefix: "DAV:", namespaces: _namespaces)) {
        final status = child.children
            .whereType<XmlElement>()
            .firstWhere((element) => element.matchQualifiedName("status",
                prefix: "DAV:", namespaces: _namespaces))
            .innerText;
        if (!status.contains(" 200 ")) {
          continue;
        }
        final prop = child.children.whereType<XmlElement>().firstWhere(
            (element) => element.matchQualifiedName("prop",
                prefix: "DAV:", namespaces: _namespaces));
        final propParser =
            _FileIdPropParser(namespaces: _namespaces, logFilePath: path);
        propParser.parse(prop);
        fileId = propParser.fileId;
      }
    }

    return Favorite(
      fileId: fileId!,
    );
  }

  String _hrefToPath(XmlElement href) {
    final rawPath = Uri.decodeComponent(href.innerText).trimLeftAny("/");
    final pos = rawPath.indexOf("remote.php");
    if (pos == -1) {
      // what?
      _log.warning("[_hrefToPath] Unknown href value: $rawPath");
      return rawPath;
    } else {
      return rawPath.substring(pos);
    }
  }

  var _namespaces = <String, String>{};

  static final _log =
      Logger("entity.webdav_response_parser.WebdavResponseParser");
}

class _FilePropParser {
  _FilePropParser({
    this.namespaces = const {},
    this.logFilePath,
  });

  /// Parse <DAV:prop> element contents
  void parse(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (child.matchQualifiedName("getlastmodified",
          prefix: "DAV:", namespaces: namespaces)) {
        _lastModified = HttpDate.parse(child.innerText);
      } else if (child.matchQualifiedName("getcontentlength",
          prefix: "DAV:", namespaces: namespaces)) {
        _contentLength = int.parse(child.innerText);
      } else if (child.matchQualifiedName("getcontenttype",
          prefix: "DAV:", namespaces: namespaces)) {
        _contentType = child.innerText;
      } else if (child.matchQualifiedName("getetag",
          prefix: "DAV:", namespaces: namespaces)) {
        _etag = child.innerText.replaceAll("\"", "");
      } else if (child.matchQualifiedName("quota-used-bytes",
          prefix: "DAV:", namespaces: namespaces)) {
        _usedBytes = int.parse(child.innerText);
      } else if (child.matchQualifiedName("resourcetype",
          prefix: "DAV:", namespaces: namespaces)) {
        _isCollection = child.children.whereType<XmlElement>().any((element) =>
            element.matchQualifiedName("collection",
                prefix: "DAV:", namespaces: namespaces));
      } else if (child.matchQualifiedName("has-preview",
          prefix: "http://nextcloud.org/ns", namespaces: namespaces)) {
        _hasPreview = child.innerText == "true";
      } else if (child.matchQualifiedName("fileid",
          prefix: "http://owncloud.org/ns", namespaces: namespaces)) {
        _fileId = int.parse(child.innerText);
      } else if (child.matchQualifiedName("favorite",
          prefix: "http://owncloud.org/ns", namespaces: namespaces)) {
        _isFavorite = child.innerText != "0";
      } else if (child.matchQualifiedName("owner-id",
          prefix: "http://owncloud.org/ns", namespaces: namespaces)) {
        _ownerId = child.innerText.toCi();
      } else if (child.matchQualifiedName("trashbin-filename",
          prefix: "http://nextcloud.org/ns", namespaces: namespaces)) {
        _trashbinFilename = child.innerText;
      } else if (child.matchQualifiedName("trashbin-original-location",
          prefix: "http://nextcloud.org/ns", namespaces: namespaces)) {
        _trashbinOriginalLocation = child.innerText;
      } else if (child.matchQualifiedName("trashbin-deletion-time",
          prefix: "http://nextcloud.org/ns", namespaces: namespaces)) {
        _trashbinDeletionTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(child.innerText) * 1000);
      } else if (child.matchQualifiedName("is-archived",
          prefix: "com.nkming.nc_photos", namespaces: namespaces)) {
        _isArchived = child.innerText == "true";
      } else if (child.matchQualifiedName("override-date-time",
          prefix: "com.nkming.nc_photos", namespaces: namespaces)) {
        _overrideDateTime = DateTime.parse(child.innerText);
      }
    }
    // 2nd pass that depends on data in 1st pass
    for (final child in element.children.whereType<XmlElement>()) {
      if (child.matchQualifiedName("metadata",
          prefix: "com.nkming.nc_photos", namespaces: namespaces)) {
        _metadata = Metadata.fromJson(
          jsonDecode(child.innerText),
          upgraderV1: MetadataUpgraderV1(
            fileContentType: _contentType,
            logFilePath: logFilePath,
          ),
          upgraderV2: MetadataUpgraderV2(
            fileContentType: _contentType,
            logFilePath: logFilePath,
          ),
        );
      }
    }
  }

  DateTime? get lastModified => _lastModified;
  int? get contentLength => _contentLength;
  String? get contentType => _contentType;
  String? get etag => _etag;
  int? get usedBytes => _usedBytes;
  bool? get isCollection => _isCollection;
  bool? get hasPreview => _hasPreview;
  int? get fileId => _fileId;
  bool? get isFavorite => _isFavorite;
  CiString? get ownerId => _ownerId;
  Metadata? get metadata => _metadata;
  bool? get isArchived => _isArchived;
  DateTime? get overrideDateTime => _overrideDateTime;
  String? get trashbinFilename => _trashbinFilename;
  String? get trashbinOriginalLocation => _trashbinOriginalLocation;
  DateTime? get trashbinDeletionTime => _trashbinDeletionTime;

  final Map<String, String> namespaces;

  /// File path for logging only
  final String? logFilePath;

  DateTime? _lastModified;
  int? _contentLength;
  String? _contentType;
  String? _etag;
  int? _usedBytes;
  bool? _isCollection;
  bool? _hasPreview;
  int? _fileId;
  bool? _isFavorite;
  CiString? _ownerId;
  Metadata? _metadata;
  bool? _isArchived;
  DateTime? _overrideDateTime;
  String? _trashbinFilename;
  String? _trashbinOriginalLocation;
  DateTime? _trashbinDeletionTime;
}

class _FileIdPropParser {
  _FileIdPropParser({
    this.namespaces = const {},
    this.logFilePath,
  });

  /// Parse <DAV:prop> element contents
  void parse(XmlElement element) {
    for (final child in element.children.whereType<XmlElement>()) {
      if (child.matchQualifiedName("fileid",
          prefix: "http://owncloud.org/ns", namespaces: namespaces)) {
        _fileId = int.parse(child.innerText);
      }
    }
  }

  int? get fileId => _fileId;

  final Map<String, String> namespaces;

  /// File path for logging only
  final String? logFilePath;

  int? _fileId;
}

extension on XmlElement {
  bool matchQualifiedName(
    String local, {
    required String prefix,
    required Map<String, String> namespaces,
  }) {
    final localNamespaces = <String, String>{};
    for (final a in attributes) {
      if (a.name.prefix == "xmlns") {
        localNamespaces[a.name.local] = a.value;
      } else if (a.name.local == "xmlns") {
        localNamespaces["!"] = a.value;
      }
    }
    return name.local == local &&
        (name.prefix == prefix ||
            // match default namespace
            (name.prefix == null && namespaces["!"] == prefix) ||
            // match global namespace
            namespaces.entries
                .where((element2) => element2.value == prefix)
                .any((element) => element.key == name.prefix) ||
            // match local namespace
            localNamespaces.entries
                .where((element2) => element2.value == prefix)
                .any((element) => element.key == name.prefix));
  }
}
