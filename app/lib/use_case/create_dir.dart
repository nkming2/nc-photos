import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:path/path.dart' as path_lib;

class CreateDir {
  CreateDir(this.fileRepo);

  /// Create a directory recursively at [path]
  ///
  /// [path] should be a relative WebDAV path like
  /// remote.php/dav/files/admin/new/dir
  Future<void> call(Account account, String path) async {
    try {
      await fileRepo.createDir(account, path);
    } on ApiException catch (e) {
      if (e.response.statusCode == 409) {
        // parent dir missing
        if (path.contains("/") && path != "/") {
          await call(account, path_lib.dirname(path));
          await fileRepo.createDir(account, path);
        } else {
          // ?
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  final FileRepo fileRepo;
}
