import 'dart:typed_data';

import 'package:flutter/services.dart';

class MediaStore {
  static const exceptionCodePermissionError = "permissionError";

  static Future<String> saveFileToDownload(
      String fileName, Uint8List fileContent) async {
    return (await _channel
        .invokeMethod<String>("saveFileToDownload", <String, dynamic>{
      "fileName": fileName,
      "content": fileContent,
    }))!;
  }

  static Future<String> copyFileToDownload(
      String toFileName, String fromFilePath) async {
    return (await _channel
        .invokeMethod<String>("copyFileToDownload", <String, dynamic>{
      "toFileName": toFileName,
      "fromFilePath": fromFilePath,
    }))!;
  }

  static const _channel = MethodChannel("com.nkming.nc_photos/media_store");
}
