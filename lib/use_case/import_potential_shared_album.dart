import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/list_potential_shared_album.dart';
import 'package:nc_photos/use_case/move.dart';

/// Import new shared albums to the pending dir
class ImportPotentialSharedAlbum {
  ImportPotentialSharedAlbum(this.fileRepo, this.albumRepo);

  Future<List<Album>> call(Account account, AccountSettings settings) async {
    _log.info("[call] $account");
    final products = <Album>[];
    final files = await ListPotentialSharedAlbum(fileRepo)(account, settings);
    for (final f in files) {
      // check if the file is actually an album
      try {
        final album = await albumRepo.get(account, f);
        _log.info("[call] New shared album: ${album.name}, file: ${f.path}");
        // move this file to the pending dir
        await Move(fileRepo)(
          account,
          f,
          "${remote_storage_util.getRemotePendingSharedAlbumsDir(account)}/${f.filename}",
          shouldCreateMissingDir: true,
        );
        products.add(album);
      } catch (e, stacktrace) {
        _log.severe("[call] Exception", e, stacktrace);
      }
    }
    return products;
  }

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;

  static final _log = Logger(
      "user_case.import_potential_shared_album.ImportPotentialSharedAlbum");
}
