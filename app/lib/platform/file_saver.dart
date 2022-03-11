import 'dart:typed_data';

abstract class FileSaver {
  /// Save binary content to a file
  ///
  /// The return data depends on the platform
  /// - web: null
  /// - android: Uri to the downloaded file
  Future<dynamic> saveFile(String filename, Uint8List content);
}
