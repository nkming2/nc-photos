import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/create_share.dart';
import 'package:nc_photos/use_case/update_album.dart';

class ShareAlbumWithUser {
  ShareAlbumWithUser(this.shareRepo, this.albumRepo);

  Future<void> call(
    Account account,
    Album album,
    Sharee sharee, {
    void Function(File)? onShareFileFailed,
  }) async {
    assert(album.provider is AlbumStaticProvider);
    // add the share to album file
    final newAlbum = album.copyWith(
      shares: OrNull((album.shares ?? [])
        ..add(AlbumShare(
          userId: sharee.shareWith,
          displayName: sharee.shareWithDisplayNameUnique,
        ))),
    );
    await UpdateAlbum(albumRepo)(account, newAlbum);

    await _createFileShares(
      account,
      newAlbum,
      sharee.shareWith,
      onShareFileFailed: onShareFileFailed,
    );
  }

  Future<void> _createFileShares(
    Account account,
    Album album,
    String shareWith, {
    void Function(File)? onShareFileFailed,
  }) async {
    final files = AlbumStaticProvider.of(album)
        .items
        .whereType<AlbumFileItem>()
        .map((e) => e.file);
    try {
      await CreateUserShare(shareRepo)(account, album.albumFile!, shareWith);
    } catch (e, stackTrace) {
      _log.severe(
          "[_createFileShares] Failed sharing album file '${logFilename(album.albumFile?.path)}' with '$shareWith'",
          e,
          stackTrace);
      onShareFileFailed?.call(album.albumFile!);
    }
    for (final f in files) {
      _log.info("[_createFileShares] Sharing '${f.path}' with '$shareWith'");
      try {
        await CreateUserShare(shareRepo)(account, f, shareWith);
      } catch (e, stackTrace) {
        _log.severe(
            "[_createFileShares] Failed sharing file '${logFilename(f.path)}' with '$shareWith'",
            e,
            stackTrace);
        onShareFileFailed?.call(f);
      }
    }
  }

  final ShareRepo shareRepo;
  final AlbumRepo albumRepo;

  static final _log =
      Logger("use_case.share_album_with_user.ShareAlbumWithUser");
}
