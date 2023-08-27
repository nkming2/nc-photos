import 'dart:typed_data';

import 'package:nc_photos/platform/file_saver.dart' as itf;
import 'package:nc_photos_plugin/nc_photos_plugin.dart';
import 'package:np_platform_util/np_platform_util.dart';

class FileSaver extends itf.FileSaver {
  @override
  saveFile(String filename, Uint8List content) {
    if (getRawPlatform() == NpPlatform.android) {
      return _saveFileAndroid(filename, content);
    } else {
      throw UnimplementedError();
    }
  }

  Future<String> _saveFileAndroid(String filename, Uint8List content) =>
      MediaStore.saveFileToDownload(content, filename);
}
