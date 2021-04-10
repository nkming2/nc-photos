import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/string_extension.dart';
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

int compareFileDateTimeDescending(File x, File y) {
  final xDate = x.metadata?.exif?.dateTimeOriginal ?? x.lastModified;
  final yDate = y.metadata?.exif?.dateTimeOriginal ?? y.lastModified;
  final tmp = yDate.compareTo(xDate);
  if (tmp != 0) {
    return tmp;
  } else {
    // compare file name if files are modified at the same time
    return x.path.compareTo(y.path);
  }
}

/// Immutable object that hold metadata of a [File]
class Metadata {
  Metadata({
    DateTime lastUpdated,
    this.fileEtag,
    this.imageWidth,
    this.imageHeight,
    this.exif,
  }) : this.lastUpdated = (lastUpdated ?? DateTime.now()).toUtc();

  /// Parse Metadata from [json]
  ///
  /// If the version saved in json does not match the active one, the
  /// corresponding upgrader will be called one by one to upgrade the json,
  /// version by version until it reached the active version. If any upgrader
  /// in the chain is null, the upgrade process will fail
  factory Metadata.fromJson(
    Map<String, dynamic> json, {
    MetadataUpgraderV1 upgraderV1,
  }) {
    final jsonVersion = json["version"];
    if (jsonVersion < 2) {
      json = upgraderV1?.call(json);
      if (json == null) {
        _log.info("[fromJson] Version $jsonVersion not compatible");
        return null;
      }
    }
    return Metadata(
      lastUpdated: json["lastUpdated"] == null
          ? null
          : DateTime.parse(json["lastUpdated"]),
      fileEtag: json["fileEtag"],
      imageWidth: json["imageWidth"],
      imageHeight: json["imageHeight"],
      exif: json["exif"] == null
          ? null
          : Exif.fromJson(json["exif"].cast<String, dynamic>()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "version": version,
      "lastUpdated": lastUpdated.toIso8601String(),
      if (fileEtag != null) "fileEtag": fileEtag,
      if (imageWidth != null) "imageWidth": imageWidth,
      if (imageHeight != null) "imageHeight": imageHeight,
      if (exif != null) "exif": exif.toJson(),
    };
  }

  @override
  toString() {
    var product = "$runtimeType {"
        "lastUpdated: $lastUpdated, ";
    if (fileEtag != null) {
      product += "fileEtag: $fileEtag, ";
    }
    if (imageWidth != null) {
      product += "imageWidth: $imageWidth, ";
    }
    if (imageHeight != null) {
      product += "imageHeight: $imageHeight, ";
    }
    if (exif != null) {
      product += "exif: $exif, ";
    }
    return product + "}";
  }

  final DateTime lastUpdated;

  /// Etag of the parent file when the metadata is saved
  final String fileEtag;
  final int imageWidth;
  final int imageHeight;
  final Exif exif;

  /// versioning of this class, use to upgrade old persisted metadata
  static const version = 2;

  static final _log = Logger("entity.file.Metadata");
}

abstract class MetadataUpgrader {
  Map<String, dynamic> call(Map<String, dynamic> json);
}

/// Upgrade v1 Metadata to v2
class MetadataUpgraderV1 implements MetadataUpgrader {
  MetadataUpgraderV1({
    @required this.fileContentType,
  });

  Map<String, dynamic> call(Map<String, dynamic> json) {
    if (fileContentType == "image/webp") {
      // Version 1 metadata for webp is bugged, drop it
      return null;
    } else {
      return json;
    }
  }

  final String fileContentType;
}

class File {
  File({
    @required String path,
    this.contentLength,
    this.contentType,
    this.etag,
    this.lastModified,
    this.isCollection,
    this.usedBytes,
    this.hasPreview,
    this.metadata,
  }) : this.path = path.trimRightAny("/");

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
      path: json["path"],
      contentLength: json["contentLength"],
      contentType: json["contentType"],
      etag: json["etag"],
      lastModified: json["lastModified"] == null
          ? null
          : DateTime.parse(json["lastModified"]),
      isCollection: json["isCollection"],
      usedBytes: json["usedBytes"],
      hasPreview: json["hasPreview"],
      metadata: json["metadata"] == null
          ? null
          : Metadata.fromJson(
              json["metadata"].cast<String, dynamic>(),
              upgraderV1: MetadataUpgraderV1(
                fileContentType: json["contentType"],
              ),
            ),
    );
  }

  @override
  toString() {
    var product = "$runtimeType {"
        "path: '$path', ";
    if (contentLength != null) {
      product += "contentLength: $contentLength, ";
    }
    if (contentType != null) {
      product += "contentType: '$contentType', ";
    }
    if (etag != null) {
      product += "etag: '$etag', ";
    }
    if (lastModified != null) {
      product += "lastModified: $lastModified, ";
    }
    if (isCollection != null) {
      product += "isCollection: $isCollection, ";
    }
    if (usedBytes != null) {
      product += "usedBytes: $usedBytes, ";
    }
    if (hasPreview != null) {
      product += "hasPreview: $hasPreview, ";
    }
    if (metadata != null) {
      product += "metadata: $metadata, ";
    }
    return product + "}";
  }

  Map<String, dynamic> toJson() {
    return {
      "path": path,
      if (contentLength != null) "contentLength": contentLength,
      if (contentType != null) "contentType": contentType,
      if (etag != null) "etag": etag,
      if (lastModified != null) "lastModified": lastModified.toIso8601String(),
      if (isCollection != null) "isCollection": isCollection,
      if (usedBytes != null) "usedBytes": usedBytes,
      if (hasPreview != null) "hasPreview": hasPreview,
      if (metadata != null) "metadata": metadata.toJson(),
    };
  }

  File copyWith({
    String path,
    int contentLength,
    String contentType,
    String etag,
    DateTime lastModified,
    bool isCollection,
    int usedBytes,
    bool hasPreview,
    Metadata metadata,
  }) {
    return File(
      path: path ?? this.path,
      contentLength: contentLength ?? this.contentLength,
      contentType: contentType ?? this.contentType,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      isCollection: isCollection ?? this.isCollection,
      usedBytes: usedBytes ?? this.usedBytes,
      hasPreview: hasPreview ?? this.hasPreview,
      metadata: metadata ?? this.metadata,
    );
  }

  File withoutMetadata() {
    return File(
      path: path,
      contentLength: contentLength,
      contentType: contentType,
      etag: etag,
      lastModified: lastModified,
      isCollection: isCollection,
      usedBytes: usedBytes,
      hasPreview: hasPreview,
    );
  }

  /// Return the path of this file with the DAV part stripped
  String get strippedPath {
    // WebDAV path: remote.php/dav/files/{username}/{path}
    if (path.contains("remote.php/dav/files")) {
      return path
          .substring(path.indexOf("/", "remote.php/dav/files/".length) + 1);
    } else {
      return path;
    }
  }

  final String path;
  final int contentLength;
  final String contentType;
  final String etag;
  final DateTime lastModified;
  final bool isCollection;
  final int usedBytes;
  final bool hasPreview;
  // metadata
  final Metadata metadata;
}

class FileRepo {
  FileRepo(this.dataSrc);

  /// See [FileDataSource.list]
  Future<List<File>> list(Account account, File root) =>
      this.dataSrc.list(account, root);

  /// See [FileDataSource.remove]
  Future<void> remove(Account account, File file) =>
      this.dataSrc.remove(account, file);

  /// See [FileDataSource.getBinary]
  Future<Uint8List> getBinary(Account account, File file) =>
      this.dataSrc.getBinary(account, file);

  /// See [FileDataSource.putBinary]
  Future<void> putBinary(Account account, String path, Uint8List content) =>
      this.dataSrc.putBinary(account, path, content);

  /// See [FileDataSource.updateMetadata]
  Future<void> updateMetadata(Account account, File file, Metadata metadata) =>
      this.dataSrc.updateMetadata(account, file, metadata);

  final FileDataSource dataSrc;
}

abstract class FileDataSource {
  /// List all files under [f]
  Future<List<File>> list(Account account, File f);

  /// Remove file
  Future<void> remove(Account account, File f);

  /// Read file as binary array
  Future<Uint8List> getBinary(Account account, File f);

  /// Upload content to [path]
  Future<void> putBinary(Account account, String path, Uint8List content);

  /// Update metadata for a file
  ///
  /// This will completely replace the metadata of the file [f]. Partial update
  /// is not supported
  Future<void> updateMetadata(Account account, File f, Metadata metadata);
}

class FileWebdavDataSource implements FileDataSource {
  @override
  list(Account account, File f) async {
    _log.fine("[list] ${f.path}");
    final response = await Api(account).files().propfind(
      path: f.path,
      getlastmodified: 1,
      resourcetype: 1,
      getetag: 1,
      getcontenttype: 1,
      getcontentlength: 1,
      hasPreview: 1,
      customNamespaces: {
        "com.nkming.nc_photos": "app",
      },
      customProperties: [
        "app:metadata",
      ],
    );
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    final files = WebdavFileParser()(xml);
    // _log.fine("[list] Parsed files: [$files]");
    return files.map((e) {
      if (e.metadata == null || e.metadata.fileEtag == e.etag) {
        return e;
      } else {
        _log.info("[list] Ignore outdated metadata for ${e.path}");
        return e.withoutMetadata();
      }
    }).toList();
  }

  @override
  remove(Account account, File f) async {
    _log.info("[remove] ${f.path}");
    final response = await Api(account).files().delete(path: f.path);
    if (!response.isGood) {
      _log.severe("[remove] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  @override
  getBinary(Account account, File f) async {
    _log.info("[getBinary] ${f.path}");
    final response = await Api(account).files().get(path: f.path);
    if (!response.isGood) {
      _log.severe("[getBinary] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
    return response.body;
  }

  @override
  putBinary(Account account, String path, Uint8List content) async {
    _log.info("[putBinary] $path");
    final response =
        await Api(account).files().put(path: path, content: content);
    if (!response.isGood) {
      _log.severe("[putBinary] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  @override
  updateMetadata(Account account, File f, Metadata metadata) async {
    _log.info("[updateMetadata] ${f.path}");
    if (metadata != null && metadata.fileEtag != f.etag) {
      _log.warning(
          "[updateMetadata] etag mismatch (metadata: ${metadata.fileEtag}, file: ${f.etag})");
    }
    final setProps = {
      if (metadata != null) "app:metadata": jsonEncode(metadata.toJson()),
    };
    final removeProps = [
      if (metadata == null) "app:metadata",
    ];
    final response = await Api(account).files().proppatch(
          path: f.path,
          namespaces: {
            "com.nkming.nc_photos": "app",
          },
          set: setProps.isNotEmpty ? setProps : null,
          remove: removeProps.isNotEmpty ? removeProps : null,
        );
    if (!response.isGood) {
      _log.severe("[updateMetadata] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  static final _log = Logger("entity.file.FileWebdavDataSource");
}

class FileAppDbDataSource implements FileDataSource {
  @override
  list(Account account, File f) {
    _log.info("[list] ${f.path}");
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.fileStoreName);
      return await _doList(store, account, f);
    });
  }

  @override
  remove(Account account, File f) {
    _log.info("[remove] ${f.path}");
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.fileStoreName);
      // we don't yet support removing dirs
      // final range = KeyRange.bound(f.path, f.path + "\uffff");
      await store.delete(_getCacheKey(account, f));
    });
  }

  @override
  getBinary(Account account, File f) {
    _log.info("[getBinary] ${f.path}");
    throw UnimplementedError();
  }

  @override
  putBinary(Account account, String path, Uint8List content) async {
    _log.info("[putBinary] $path");
    // do nothing, we currently don't store file contents locally
  }

  @override
  updateMetadata(Account account, File f, Metadata metadata) {
    _log.info("[updateMetadata] ${f.path}");
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.fileStoreName);
      final parentDir = File(path: path.dirname(f.path));
      final parentList = await _doList(store, account, parentDir);
      final jsonList = parentList.map((e) {
        if (e.path == f.path) {
          return e.copyWith(metadata: metadata).toJson();
        } else {
          return e.toJson();
        }
      }).toList();
      await store.put(jsonList, _getCacheKey(account, parentDir));
    });
  }

  Future<List<File>> _doList(ObjectStore store, Account account, File f) async {
    final List result = await store.getObject("${_getCacheKey(account, f)}");
    if (result != null) {
      return result
          .cast<Map<dynamic, dynamic>>()
          .map((e) => File.fromJson(e.cast()))
          .toList();
    } else {
      throw CacheNotFoundException("No entry: ${_getCacheKey(account, f)}");
    }
  }

  static final _log = Logger("entity.file.FileAppDbDataSource");
}

class FileCachedDataSource implements FileDataSource {
  @override
  list(Account account, File f) async {
    final trimmedRootPath = f.path.trimAny("/");
    List<File> cache;
    try {
      cache = await _appDbSrc.list(account, f);
      // compare the cached root
      final cacheRoot = cache.firstWhere(
          (element) => element.path.trimAny("/") == trimmedRootPath,
          orElse: () => null);
      if (cacheRoot?.etag?.isNotEmpty == true && cacheRoot.etag == f.etag) {
        // cache is good
        _log.fine("[list] etag matched for ${_getCacheKey(account, f)}");
        return cache;
      } else {
        _log.info(
            "[list] Remote content updated for ${_getCacheKey(account, f)}");
      }
    } catch (e, stacktrace) {
      // no cache
      if (e is! CacheNotFoundException) {
        _log.severe("[list] Cache failure", e, stacktrace);
      }
    }

    // no cache
    try {
      final remote = await _remoteSrc.list(account, f);
      await _cacheResult(account, f, remote);
      if (cache != null) {
        try {
          await _cleanUpCachedList(account, remote, cache);
        } catch (e, stacktrace) {
          _log.severe("[list] Failed while _cleanUpCachedList", e, stacktrace);
          // ignore error
        }
      }
      return remote;
    } on ApiException catch (e) {
      if (e.response.statusCode == 404) {
        _log.info("[list] File removed: $f");
        _appDbSrc.remove(account, f);
        return [];
      } else {
        rethrow;
      }
    }
  }

  @override
  remove(Account account, File f) async {
    await _appDbSrc.remove(account, f);
    await _remoteSrc.remove(account, f);
  }

  @override
  getBinary(Account account, File f) {
    return _remoteSrc.getBinary(account, f);
  }

  @override
  putBinary(Account account, String path, Uint8List content) async {
    await _remoteSrc.putBinary(account, path, content);
  }

  @override
  updateMetadata(Account account, File f, Metadata metadata) async {
    await _remoteSrc
        .updateMetadata(account, f, metadata)
        .then((_) => _appDbSrc.updateMetadata(account, f, metadata));
  }

  Future<void> _cacheResult(Account account, File f, List<File> result) {
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.fileStoreName);
      await store.put(
          result.map((e) => e.toJson()).toList(), _getCacheKey(account, f));
    });
  }

  Future<void> _cleanUpCachedList(
      Account account, List<File> remoteResults, List<File> cachedResults) {
    final removed = cachedResults
        .where((cache) =>
            !remoteResults.any((remote) => remote.path == cache.path))
        .toList();
    if (removed.isEmpty) {
      return Future.delayed(Duration.zero);
    }
    _log.info(
        "[_cleanUpCachedList] Removing cache: ${removed.toReadableString()}");
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.fileStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.fileStoreName);
      for (final r in removed) {
        final key = _getCacheKey(account, r);
        _log.fine("[_cleanUpCachedList] Removing DB entry: $key");
        // delete the dir itself
        await store.delete(key);

        // then its children
        final range = KeyRange.bound("$key/", "$key/\uffff");
        // delete with KeyRange is not supported in idb_shim/idb_sqflite
        // await store.delete(range);
        final keys = await store
            .openKeyCursor(range: range, autoAdvance: true)
            .map((cursor) => cursor.key)
            .toList();
        for (final k in keys) {
          _log.fine("[_cleanUpCachedList] Removing DB entry: $k");
          await store.delete(k);
        }
      }
    });
  }

  final _remoteSrc = FileWebdavDataSource();
  final _appDbSrc = FileAppDbDataSource();

  static final _log = Logger("entity.file.FileCachedDataSource");
}

String _getCacheKey(Account account, File file) =>
    "${account.url}/${file.path}";
