import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/move.dart';

/// Unimport a shared album from the library
class UnimportSharedAlbum {
  const UnimportSharedAlbum(this.fileRepo);

  Future<void> call(Account account, Album album) async {
    final destination =
        "${remote_storage_util.getRemotePendingSharedAlbumsDir(account)}/${album.albumFile!.filename}";
    await Move(fileRepo)(
      account,
      album.albumFile!,
      destination,
      shouldCreateMissingDir: true,
    );
  }

  final FileRepo fileRepo;
}
