import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/mobile/android/media_store.dart';
import 'package:nc_photos/platform/file_saver.dart' as itf;
import 'package:nc_photos/platform/k.dart' as platform_k;

class FileSaver extends itf.FileSaver {
  @override
  saveFile(String filename, Uint8List content) {
    if (platform_k.isAndroid) {
      return _saveFileAndroid(filename, content);
    } else {
      throw UnimplementedError();
    }
  }

  Future<String> _saveFileAndroid(String filename, Uint8List content) async {
    try {
      return await MediaStore.saveFileToDownload(filename, content);
    } on PlatformException catch (e) {
      if (e.code == MediaStore.exceptionCodePermissionError) {
        throw PermissionException();
      } else {
        rethrow;
      }
    }
  }
}
