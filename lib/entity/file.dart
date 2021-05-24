import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/string_extension.dart';

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
class Metadata with EquatableMixin {
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
    MetadataUpgraderV2 upgraderV2,
  }) {
    final jsonVersion = json["version"];
    if (jsonVersion < 2) {
      json = upgraderV1?.call(json);
      if (json == null) {
        _log.info("[fromJson] Version $jsonVersion not compatible");
        return null;
      }
    }
    if (jsonVersion < 3) {
      json = upgraderV2?.call(json);
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

  @override
  get props => [
        lastUpdated,
        fileEtag,
        imageWidth,
        imageHeight,
        exif,
      ];

  final DateTime lastUpdated;

  /// Etag of the parent file when the metadata is saved
  final String fileEtag;
  final int imageWidth;
  final int imageHeight;
  final Exif exif;

  /// versioning of this class, use to upgrade old persisted metadata
  static const version = 3;

  static final _log = Logger("entity.file.Metadata");
}

abstract class MetadataUpgrader {
  Map<String, dynamic> call(Map<String, dynamic> json);
}

/// Upgrade v1 Metadata to v2
class MetadataUpgraderV1 implements MetadataUpgrader {
  MetadataUpgraderV1({
    @required this.fileContentType,
    this.logFilePath,
  });

  Map<String, dynamic> call(Map<String, dynamic> json) {
    if (fileContentType == "image/webp") {
      // Version 1 metadata for webp is bugged, drop it
      _log.fine("[call] Upgrade v1 metadata for file: $logFilePath");
      return null;
    } else {
      return json;
    }
  }

  final String fileContentType;

  /// File path for logging only
  final String logFilePath;

  static final _log = Logger("entity.file.MetadataUpgraderV1");
}

/// Upgrade v2 Metadata to v3
class MetadataUpgraderV2 implements MetadataUpgrader {
  MetadataUpgraderV2({
    @required this.fileContentType,
    this.logFilePath,
  });

  Map<String, dynamic> call(Map<String, dynamic> json) {
    if (fileContentType == "image/jpeg") {
      // Version 2 metadata for jpeg doesn't consider orientation
      if (json["exif"] != null && json["exif"].containsKey("Orientation")) {
        // Check orientation
        final orientation = json["exif"]["Orientation"];
        if (orientation >= 5 && orientation <= 8) {
          _log.fine("[call] Upgrade v2 metadata for file: $logFilePath");
          final temp = json["imageWidth"];
          json["imageWidth"] = json["imageHeight"];
          json["imageHeight"] = temp;
        }
      }
    }
    return json;
  }

  final String fileContentType;

  /// File path for logging only
  final String logFilePath;

  static final _log = Logger("entity.file.MetadataUpgraderV2");
}

class File with EquatableMixin {
  File({
    @required String path,
    this.contentLength,
    this.contentType,
    this.etag,
    this.lastModified,
    this.isCollection,
    this.usedBytes,
    this.hasPreview,
    this.fileId,
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
      fileId: json["fileId"],
      metadata: json["metadata"] == null
          ? null
          : Metadata.fromJson(
              json["metadata"].cast<String, dynamic>(),
              upgraderV1: MetadataUpgraderV1(
                fileContentType: json["contentType"],
                logFilePath: json["path"],
              ),
              upgraderV2: MetadataUpgraderV2(
                fileContentType: json["contentType"],
                logFilePath: json["path"],
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
    if (fileId != null) {
      product += "fileId: '$fileId', ";
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
      if (fileId != null) "fileId": fileId,
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
    int fileId,
    OrNull<Metadata> metadata,
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
      fileId: fileId ?? this.fileId,
      metadata: metadata == null ? this.metadata : metadata.obj,
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

  @override
  get props => [
        path,
        contentLength,
        contentType,
        etag,
        lastModified,
        isCollection,
        usedBytes,
        hasPreview,
        fileId,
        metadata,
      ];

  final String path;
  final int contentLength;
  final String contentType;
  final String etag;
  final DateTime lastModified;
  final bool isCollection;
  final int usedBytes;
  final bool hasPreview;
  // maybe null when loaded from old cache
  final int fileId;
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

  /// See [FileDataSource.copy]
  Future<void> copy(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
  }) =>
      this.dataSrc.copy(
            account,
            f,
            destination,
            shouldOverwrite: shouldOverwrite,
          );

  /// See [FileDataSource.move]
  Future<void> move(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
  }) =>
      this.dataSrc.move(
            account,
            f,
            destination,
            shouldOverwrite: shouldOverwrite,
          );

  /// See [FileDataSource.createDir]
  Future<void> createDir(Account account, String path) =>
      this.dataSrc.createDir(account, path);

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

  /// Copy [f] to [destination]
  ///
  /// [destination] should be a relative WebDAV path like
  /// remote.php/dav/files/admin/new/location
  Future<void> copy(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
  });

  /// Move [f] to [destination]
  ///
  /// [destination] should be a relative WebDAV path like
  /// remote.php/dav/files/admin/new/location
  Future<void> move(
    Account account,
    File f,
    String destination, {
    bool shouldOverwrite,
  });

  /// Create a directory at [path]
  ///
  /// [path] should be a relative WebDAV path like
  /// remote.php/dav/files/admin/new/dir
  Future<void> createDir(Account account, String path);
}
