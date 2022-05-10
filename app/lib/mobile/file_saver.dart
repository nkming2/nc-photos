import 'dart:typed_data';

import 'package:nc_photos/platform/file_saver.dart' as itf;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

class FileSaver extends itf.FileSaver {
  @override
  saveFile(String filename, Uint8List content) {
    if (platform_k.isAndroid) {
      return _saveFileAndroid(filename, content);
    } else {
      throw UnimplementedError();
    }
  }

  Future<String> _saveFileAndroid(String filename, Uint8List content) =>
      MediaStore.saveFileToDownload(content, filename);
}
