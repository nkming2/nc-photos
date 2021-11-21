import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:nc_photos/use_case/move.dart';

/// Import a shared album from the pending dir to the library
class ImportPendingSharedAlbum {
  const ImportPendingSharedAlbum(this.fileRepo, this.albumRepo);

  Future<Album> call(Account account, Album album) async {
    final destination =
        "${remote_storage_util.getRemoteAlbumsDir(account)}/${album.albumFile!.filename}";
    await Move(fileRepo)(
      account,
      album.albumFile!,
      destination,
      shouldCreateMissingDir: true,
    );
    final newAlbumFile = await LsSingleFile(fileRepo)(account, destination);
    final newAlbum = await albumRepo.get(account, newAlbumFile);
    return newAlbum;
  }

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;
}
