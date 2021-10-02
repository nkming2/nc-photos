import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/move.dart';

/// Import a shared album from the pending dir to the library
class ImportPendingSharedAlbum {
  ImportPendingSharedAlbum(this.fileRepo);

  Future<void> call(Account account, File albumFile) => Move(fileRepo)(
        account,
        albumFile,
        "${remote_storage_util.getRemoteAlbumsDir(account)}/${albumFile.filename}",
        shouldCreateMissingDir: true,
      );

  final FileRepo fileRepo;
}
