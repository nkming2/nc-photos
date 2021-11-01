import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/remove_share.dart';
import 'package:nc_photos/use_case/unshare_file_from_album.dart';

class RemoveAlbum {
  const RemoveAlbum(this.fileRepo, this.albumRepo, this.shareRepo, this.pref);

  /// Remove an album
  Future<void> call(Account account, Album album) async {
    _log.info("[call] Remove album: $album");
    if (pref.isLabEnableSharedAlbumOr(false)) {
      final files = <File>[];
      if (album.provider is AlbumStaticProvider) {
        files.addAll(AlbumStaticProvider.of(album)
            .items
            .whereType<AlbumFileItem>()
            .map((e) => e.file));
      }
      final albumShares =
          (await ListShare(shareRepo)(account, album.albumFile!))
              .where((element) => element.shareType == ShareType.user)
              .toList();
      final albumShareWith = albumShares.map((e) => e.shareWith!).toList();
      // remove file shares if necessary
      if (files.isNotEmpty && albumShareWith.isNotEmpty) {
        try {
          await UnshareFileFromAlbum(shareRepo, fileRepo, albumRepo)(
              account, album, files, albumShareWith);
        } catch (e, stackTrace) {
          _log.severe(
              "[call] Failed while UnshareFileFromAlbum", e, stackTrace);
        }
      }
      // then remove the album file
      // Nextcloud currently will restore also the shares after restoring from
      // trash, but we aren't handling it for the files, so
      for (final s in albumShares) {
        try {
          await RemoveShare(shareRepo)(account, s);
        } catch (e, stackTrace) {
          _log.severe("[call] Failed while RemoveShare: $s", e, stackTrace);
        }
      }
    }
    // you can't add an album to another album, so passing null here can save
    // a few queries
    await Remove(fileRepo, null)(account, album.albumFile!);
  }

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;
  final ShareRepo shareRepo;
  final Pref pref;

  static final _log = Logger("use_case.remove_album.RemoveAlbum");
}
