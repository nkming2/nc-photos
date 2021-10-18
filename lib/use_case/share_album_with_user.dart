import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/use_case/create_share.dart';

class ShareAlbumWithUser {
  ShareAlbumWithUser(this.shareRepo);

  Future<void> call(
    Account account,
    Album album,
    String shareWith, {
    void Function(File)? onShareFileFailed,
  }) async {
    assert(album.provider is AlbumStaticProvider);
    final files = AlbumStaticProvider.of(album)
        .items
        .whereType<AlbumFileItem>()
        .map((e) => e.file);
    await CreateUserShare(shareRepo)(account, album.albumFile!, shareWith);
    for (final f in files) {
      _log.info("[call] Sharing '${f.path}' with '$shareWith'");
      try {
        await CreateUserShare(shareRepo)(account, f, shareWith);
      } catch (e, stackTrace) {
        _log.severe(
            "[call] Failed sharing file '${logFilename(f.path)}' with '$shareWith'",
            e,
            stackTrace);
        onShareFileFailed?.call(f);
      }
    }
  }

  final ShareRepo shareRepo;

  static final _log =
      Logger("use_case.share_album_with_user.ShareAlbumWithUser");
}
