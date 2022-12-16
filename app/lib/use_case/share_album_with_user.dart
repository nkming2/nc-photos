import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/create_share.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:np_codegen/np_codegen.dart';

part 'share_album_with_user.g.dart';

@npLog
class ShareAlbumWithUser {
  ShareAlbumWithUser(this.shareRepo, this.albumRepo);

  Future<Album> call(
    Account account,
    Album album,
    Sharee sharee, {
    void Function(File)? onShareFileFailed,
  }) async {
    assert(album.provider is AlbumStaticProvider);
    final newShares = (album.shares ?? [])
      ..add(AlbumShare(
        userId: sharee.shareWith,
        displayName: sharee.label,
      ));
    // add the share to album file
    final newAlbum = album.copyWith(
      shares: OrNull(newShares.distinct()),
    );
    await UpdateAlbum(albumRepo)(account, newAlbum);

    try {
      await _createFileShares(
        account,
        newAlbum,
        sharee.shareWith,
        onShareFileFailed: onShareFileFailed,
      );
    } catch (e, stackTrace) {
      _log.shout("[call] Failed while _createFileShares", e, stackTrace);
    }
    return newAlbum;
  }

  Future<void> _createFileShares(
    Account account,
    Album album,
    CiString shareWith, {
    void Function(File)? onShareFileFailed,
  }) async {
    final files = AlbumStaticProvider.of(album)
        .items
        .whereType<AlbumFileItem>()
        .where((item) => item.file.ownerId != shareWith)
        .map((e) => e.file);
    try {
      await CreateUserShare(shareRepo)(
          account, album.albumFile!, shareWith.raw);
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
        await CreateUserShare(shareRepo)(account, f, shareWith.raw);
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
}
