import 'dart:io';
import 'dart:typed_data';

import 'package:nc_photos/platform/universal_storage.dart' as itf;
import 'package:nc_photos/string_extension.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class UniversalStorage extends itf.UniversalStorage {
  @override
  putBinary(String name, Uint8List content) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    await file.writeAsBytes(content, flush: true);
  }

  @override
  getBinary(String name) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    if (await file.exists()) {
      return await file.readAsBytes();
    } else {
      return null;
    }
  }

  @override
  putString(String name, String content) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    await file.writeAsString(content, flush: true);
  }

  @override
  getString(String name) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      return null;
    }
  }

  @override
  remove(String name) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Open and return the directory for storing a file to [relativePath]
  Future<Directory> _openStorageDirForFile(String relativePath) async {
    final privateDir = await getApplicationSupportDirectory();
    final rootPath = "${privateDir.path}/universal_storage";
    final dirPath = path.dirname("$rootPath/${relativePath.trimAny('/')}");
    final storageDir = Directory(dirPath);
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    return Directory(rootPath);
  }
}
