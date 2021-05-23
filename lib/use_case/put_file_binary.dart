import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/use_case/create_dir.dart';
import 'package:path/path.dart' as path_lib;

class PutFileBinary {
  PutFileBinary(this.fileRepo);

  /// Upload file to [path]
  Future<void> call(
    Account account,
    String path,
    Uint8List content, {
    bool shouldCreateMissingDir = false,
  }) async {
    try {
      await fileRepo.putBinary(account, path, content);
    } catch (e) {
      if (e is ApiException &&
          e.response.statusCode == 404 &&
          shouldCreateMissingDir) {
        // no dir
        _log.info("[call] Auto creating parent dirs");
        await CreateDir(fileRepo)(account, path_lib.dirname(path));
        await fileRepo.putBinary(account, path, content);
      } else {
        rethrow;
      }
    }
  }

  final FileRepo fileRepo;

  static final _log = Logger("use_case.put_file_binary.PutFileBinary");
}
