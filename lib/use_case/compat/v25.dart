import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/use_case/move.dart';
import 'package:path/path.dart' as path;

/// Compatibility helper for v25
class CompatV25 {
  /// Return whether the album file need to be migrated to the new naming scheme
  static bool isAlbumFileNeedMigration(File albumFile) =>
      albumFile.path.endsWith(".nc_album.json") == false;

  /// Migrate an album file to the new naming scheme
  static Future<File> migrateAlbumFile(
          FileRepo fileRepo, Account account, File albumFile) =>
      _MigrateAlbumFile(fileRepo)(account, albumFile);
}

class _MigrateAlbumFile {
  _MigrateAlbumFile(this.fileRepo);

  Future<File> call(Account account, File albumFile) async {
    assert(CompatV25.isAlbumFileNeedMigration(albumFile));
    final newPath = path.dirname(albumFile.path) +
        "/" +
        path.basenameWithoutExtension(albumFile.path) +
        ".nc_album.json";
    _log.info("[call] Migrate album file from '${albumFile.path}' to '$newPath'");
    await Move(fileRepo)(account, albumFile, newPath);
    return albumFile.copyWith(path: newPath);
  }

  final FileRepo fileRepo;

  static final _log = Logger("use_case.compat.v25._MigrateAlbumFile");
}
