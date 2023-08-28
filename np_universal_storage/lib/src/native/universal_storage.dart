import 'dart:io';
import 'dart:typed_data';

import 'package:np_string/np_string.dart';
import 'package:np_universal_storage/src/universal_storage.dart' as itf;
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';

class UniversalStorage implements itf.UniversalStorage {
  @override
  Future<void> putBinary(String name, Uint8List content) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    await file.writeAsBytes(content, flush: true);
  }

  @override
  Future<Uint8List?> getBinary(String name) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    if (await file.exists()) {
      return await file.readAsBytes();
    } else {
      return null;
    }
  }

  @override
  Future<void> putString(String name, String content) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    await file.writeAsString(content, flush: true);
  }

  @override
  Future<String?> getString(String name) async {
    final storageDir = await _openStorageDirForFile(name);
    final file = File("${storageDir.path}/$name");
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      return null;
    }
  }

  @override
  Future<void> remove(String name) async {
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
    final dirPath = path_lib.dirname("$rootPath/${relativePath.trimAny('/')}");
    final storageDir = Directory(dirPath);
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    return Directory(rootPath);
  }
}
