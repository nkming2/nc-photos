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

  static const _channel = MethodChannel("com.nkming.nc_photos/media_store");
}
