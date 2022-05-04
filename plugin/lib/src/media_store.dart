import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nc_photos_plugin/src/exception.dart';
import 'package:nc_photos_plugin/src/k.dart' as k;

class MediaStoreQueryResult {
  const MediaStoreQueryResult(this.uri, this.displayName, this.path,
      this.dateModified, this.mimeType, this.dateTaken);

  final String uri;
  final String displayName;
  final String path;
  final int dateModified;
  final String? mimeType;
  final int? dateTaken;
}

class MediaStore {
  static Future<String> saveFileToDownload(
    Uint8List content,
    String filename, {
    String? subDir,
  }) async {
    try {
      return (await _methodChannel
          .invokeMethod<String>("saveFileToDownload", <String, dynamic>{
        "content": content,
        "filename": filename,
        "subDir": subDir,
      }))!;
    } on PlatformException catch (e) {
      if (e.code == _exceptionCodePermissionError) {
        throw const PermissionException();
      } else {
        rethrow;
      }
    }
  }

  /// Copy a file to the user Download dir
  ///
  /// [fromFile] must be either a path or a content uri. If [filename] is not
  /// null, it will be used instead of the source filename
  static Future<String> copyFileToDownload(
    String fromFile, {
    String? filename,
    String? subDir,
  }) async {
    try {
      return (await _methodChannel
          .invokeMethod<String>("copyFileToDownload", <String, dynamic>{
        "fromFile": fromFile,
        "filename": filename,
        "subDir": subDir,
      }))!;
    } on PlatformException catch (e) {
      if (e.code == _exceptionCodePermissionError) {
        throw const PermissionException();
      } else {
        rethrow;
      }
    }
  }

  /// Return files under [relativePath] and its sub dirs
  static Future<List<MediaStoreQueryResult>> queryFiles(
      String relativePath) async {
    try {
      final List results =
          await _methodChannel.invokeMethod("queryFiles", <String, dynamic>{
        "relativePath": relativePath,
      });
      return results
          .cast<Map>()
          .map((e) => MediaStoreQueryResult(e["uri"], e["displayName"],
              e["path"], e["dateModified"], e["mimeType"], e["dateTaken"]))
          .toList();
    } on PlatformException catch (e) {
      if (e.code == _exceptionCodePermissionError) {
        throw const PermissionException();
      } else {
        rethrow;
      }
    }
  }

  static const _methodChannel = MethodChannel("${k.libId}/media_store_method");

  static const _exceptionCodePermissionError = "permissionError";
}
