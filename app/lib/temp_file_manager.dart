import 'dart:io';

import 'package:logging/logging.dart';
import 'package:np_log/np_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'temp_file_manager.g.dart';

@npLog
class TempFileManager {
  const TempFileManager(this.collectionName);

  Future<File> createUnnamedFile({String? extension}) async {
    final rootDir = await _openTempDir();
    while (true) {
      final filename = const Uuid().v4();
      final n = "$filename${extension == null ? '' : '.$extension'}";
      final file = File("${rootDir.path}/$n");
      if (await file.exists()) {
        continue;
      }
      await file.create();
      return file;
    }
  }

  Future<({Directory dir, File file})> createNamedFile(
    String filename, {
    String? extension,
  }) async {
    final rootDir = await _openTempDir();
    while (true) {
      final subdirName = const Uuid().v4();
      final subdir = Directory("${rootDir.path}/$subdirName");
      if (await FileSystemEntity.type(subdir.path) !=
          FileSystemEntityType.notFound) {
        continue;
      }
      await subdir.create();
      final n = "$filename${extension == null ? '' : '.$extension'}";
      return (dir: subdir, file: File("${subdir.path}/$n"));
    }
  }

  Future<void> cleanUp() async {
    final rootDir = await _openTempDir();
    await for (final f in rootDir.list(followLinks: false)) {
      _log.warning("[cleanUp] Deleting file: ${f.path}");
      try {
        await f.delete(recursive: true);
      } catch (e, stackTrace) {
        _log.severe("[cleanUp] Failed while delete", e, stackTrace);
      }
    }
  }

  Future<Directory> _openTempDir() async {
    final root = await getTemporaryDirectory();
    final dir = Directory("${root.path}/$collectionName");
    if (!await dir.exists()) {
      return dir.create();
    } else {
      return dir;
    }
  }

  final String collectionName;
}
