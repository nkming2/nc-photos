import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/remove_share.dart';

class UnshareFileFromAlbum {
  const UnshareFileFromAlbum(this.shareRepo, this.fileRepo, this.albumRepo);

  /// Remove file shares created for an album
  ///
  /// Since a file may live in several albums, this will check across all albums
  /// and only remove shares exclusive to [album]
  Future<void> call(
    Account account,
    Album album,
    List<File> files,
    List<String> unshareWith, {
    void Function(Share)? onUnshareFileFailed,
  }) async {
    _log.info(
        "[call] Unshare ${files.length} files from album '${album.name}' with ${unshareWith.length} users");
    // list albums with shares identical to any element in [unshareWith]
    final otherAlbums = (await ListAlbum(fileRepo, albumRepo)(account)
        .where((event) => event is Album)
        .cast<Album>()
        .where((album) =>
            !album.albumFile!.compareServerIdentity(album.albumFile!) &&
            album.provider is AlbumStaticProvider &&
            album.shares?.any((s) => unshareWith.contains(s.userId)) == true)
        .toList());

    // look for shares that are exclusive to this album
    final exclusiveShares = <Share>[];
    for (final f in files) {
      try {
        final shares = await ListShare(shareRepo)(account, f);
        exclusiveShares.addAll(
            shares.where((element) => unshareWith.contains(element.shareWith)));
      } catch (e, stackTrace) {
        _log.severe("[call] Failed while ListShare: '${logFilename(f.path)}'",
            e, stackTrace);
      }
    }
    for (final a in otherAlbums) {
      // check if the album is shared with the same users
      if (!a.shares!
          .any((as) => exclusiveShares.any((s) => s.shareWith == as.userId))) {
        continue;
      }
      final albumFiles = AlbumStaticProvider.of(a)
          .items
          .whereType<AlbumFileItem>()
          .map((e) => e.file)
          .toList();
      exclusiveShares.removeWhere(
          (s) => albumFiles.any((element) => element.fileId == s.itemSource));
    }

    // unshare them
    await _unshare(account, exclusiveShares, onUnshareFileFailed);
  }

  Future<void> _unshare(Account account, List<Share> shares,
      void Function(Share)? onUnshareFileFailed) async {
    for (final s in shares) {
      try {
        await RemoveShare(shareRepo)(account, s);
      } catch (e, stackTrace) {
        _log.severe(
            "[_unshare] Failed while RemoveShare: ${s.path}", e, stackTrace);
        onUnshareFileFailed?.call(s);
      }
    }
  }

  final ShareRepo shareRepo;
  final FileRepo fileRepo;
  final AlbumRepo albumRepo;

  static final _log =
      Logger("use_case.unshare_file_from_album.UnshareFileFromAlbum");
}
