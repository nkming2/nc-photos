import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nc_photos/exception.dart';

class MediaStore {
  static Future<String> saveFileToDownload(
      String fileName, Uint8List fileContent) async {
    try {
      return (await _channel
          .invokeMethod<String>("saveFileToDownload", <String, dynamic>{
        "fileName": fileName,
        "content": fileContent,
      }))!;
    } on PlatformException catch (e) {
      if (e.code == _exceptionCodePermissionError) {
        throw PermissionException();
      } else {
        rethrow;
      }
    }
  }

  static Future<String> copyFileToDownload(
      String toFileName, String fromFilePath) async {
    try {
      return (await _channel
          .invokeMethod<String>("copyFileToDownload", <String, dynamic>{
        "toFileName": toFileName,
        "fromFilePath": fromFilePath,
      }))!;
    } on PlatformException catch (e) {
      if (e.code == _exceptionCodePermissionError) {
        throw PermissionException();
      } else {
        rethrow;
      }
    }
  }

  static const _exceptionCodePermissionError = "permissionError";

  static const _channel = MethodChannel("com.nkming.nc_photos/media_store");
}
