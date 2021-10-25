import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/list_shared_album.dart';
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
    List<ListSharedAlbumItem>? listSharedAlbumResults,
    void Function(Share)? onUnshareFileFailed,
  }) async {
    _log.info(
        "[call] Unshare ${files.length} files from album '${album.name}' with ${unshareWith.length} users");
    // list albums with shares identical to one of [unshareWith]
    final otherAlbums = (listSharedAlbumResults ??
            await ListSharedAlbum(shareRepo, fileRepo, albumRepo)(account))
        .where((element) =>
            !element.album.albumFile!.compareServerIdentity(album.albumFile!) &&
            element.album.provider is AlbumStaticProvider &&
            unshareWith.contains(element.share.shareWith))
        .toList();

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
      final albumFiles = AlbumStaticProvider.of(a.album)
          .items
          .whereType<AlbumFileItem>()
          .map((e) => e.file)
          .toList();
      exclusiveShares.removeWhere((s) =>
          a.share.shareWith == s.shareWith &&
          albumFiles.any((element) => element.fileId == s.itemSource));
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
