import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/remove_share.dart';
import 'package:nc_photos/use_case/unshare_file_from_album.dart';
import 'package:nc_photos/use_case/update_album.dart';

class RemoveAlbum {
  const RemoveAlbum(this.fileRepo, this.albumRepo, this.shareRepo, this.pref);

  /// Remove an album
  Future<void> call(Account account, Album album) async {
    _log.info("[call] Remove album: $album");
    if (pref.isLabEnableSharedAlbumOr(false)) {
      // remove shares from the album json. This should be the first so if this
      // fail the whole op can fail safely
      await UpdateAlbum(albumRepo)(
        account,
        album.copyWith(
          shares: OrNull(null),
        ),
      );
      // remove file shares
      await _unshareFiles(account, album);
      // remove shares for the album json itself
      await _unshareAlbumFile(account, album);
    }
    // you can't add an album to another album, so passing null here can save
    // a few queries
    await Remove(fileRepo, null)(account, album.albumFile!);
  }

  Future<void> _unshareFiles(Account account, Album album) async {
    if (album.shares?.isNotEmpty != true ||
        album.provider is! AlbumStaticProvider) {
      return;
    }
    final albumShares = (album.shares!.map((e) => e.userId).toList()
          ..add(album.albumFile!.ownerId ?? account.username))
        .where((element) => element != account.username)
        .toList();
    if (albumShares.isEmpty) {
      return;
    }
    final files = AlbumStaticProvider.of(album)
        .items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .toList();
    if (files.isEmpty) {
      return;
    }
    try {
      await UnshareFileFromAlbum(shareRepo, fileRepo, albumRepo)(
          account, album, files, albumShares);
    } catch (e, stackTrace) {
      _log.shout(
          "[_unshareFiles] Failed while UnshareFileFromAlbum", e, stackTrace);
    }
  }

  Future<void> _unshareAlbumFile(Account account, Album album) async {
    final shares = (await ListShare(shareRepo)(account, album.albumFile!))
        .where((s) => s.shareType == ShareType.user);
    for (final s in shares) {
      try {
        await RemoveShare(shareRepo)(account, s);
      } catch (e, stackTrace) {
        _log.shout(
            "[_unshareAlbumFile] Failed while RemoveShare: $s", e, stackTrace);
      }
    }
  }

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;
  final ShareRepo shareRepo;
  final Pref pref;

  static final _log = Logger("use_case.remove_album.RemoveAlbum");
}
