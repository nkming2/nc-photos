import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/remove_share.dart';
import 'package:nc_photos/use_case/unshare_file_from_album.dart';
import 'package:nc_photos/use_case/update_album.dart';

class UnshareAlbumWithUser {
  UnshareAlbumWithUser(this.shareRepo, this.fileRepo, this.albumRepo);

  Future<Album> call(
    Account account,
    Album album,
    CiString shareWith, {
    void Function(Share)? onUnshareFileFailed,
  }) async {
    assert(album.provider is AlbumStaticProvider);
    // remove the share from album file
    final newShares =
        album.shares?.where((s) => s.userId != shareWith).toList() ?? [];
    final newAlbum = album.copyWith(
      shares: OrNull(newShares.isEmpty ? null : newShares),
    );
    await UpdateAlbum(albumRepo)(account, newAlbum);

    try {
      await _deleteFileShares(
        account,
        newAlbum,
        shareWith,
        onUnshareFileFailed: onUnshareFileFailed,
      );
    } catch (e, stackTrace) {
      _log.shout("[call] Failed while _deleteFileShares", e, stackTrace);
    }
    return newAlbum;
  }

  Future<void> _deleteFileShares(
    Account account,
    Album album,
    CiString shareWith, {
    void Function(Share)? onUnshareFileFailed,
  }) async {
    // remove share from the album file
    final albumShares = await ListShare(shareRepo)(account, album.albumFile!);
    for (final s in albumShares.where((s) => s.shareWith == shareWith)) {
      try {
        await RemoveShare(shareRepo)(account, s);
      } catch (e, stackTrace) {
        _log.severe(
            "[_deleteFileShares] Failed unsharing album file '${logFilename(album.albumFile?.path)}' with '$shareWith'",
            e,
            stackTrace);
        onUnshareFileFailed?.call(s);
      }
    }

    // then remove shares from all files in this album
    final files = AlbumStaticProvider.of(album)
        .items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .toList();
    await UnshareFileFromAlbum(shareRepo, fileRepo, albumRepo)(
      account,
      album,
      files,
      [shareWith],
      onUnshareFileFailed: onUnshareFileFailed,
    );
  }

  final ShareRepo shareRepo;
  final FileRepo fileRepo;
  final AlbumRepo albumRepo;

  static final _log =
      Logger("use_case.unshare_album_with_user.UnshareAlbumWithUser");
}
