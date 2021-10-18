import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/list_shared_album.dart';
import 'package:nc_photos/use_case/remove_share.dart';

class UnshareAlbumWithUser {
  UnshareAlbumWithUser(this.shareRepo, this.fileRepo, this.albumRepo);

  Future<void> call(
    Account account,
    Album album,
    String shareWith, {
    void Function(File)? onUnshareFileFailed,
  }) async {
    assert(album.provider is AlbumStaticProvider);
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    final sharedItems =
        await ListSharedAlbum(shareRepo, fileRepo, albumRepo)(account);
    final thisShare = sharedItems
        .firstWhere((element) =>
            element.share.path == album.albumFile!.strippedPath &&
            element.share.shareWith == shareWith)
        .share;
    final otherSharedAlbums = sharedItems
        .where((element) =>
            !identical(element.share, thisShare) &&
            element.album.provider is AlbumStaticProvider &&
            element.share.shareWith == shareWith)
        .map((e) => e.album)
        .toList();

    final unsharingFiles = await _getExclusiveSharedFiles(
        account, album, otherSharedAlbums, shareWith);
    await RemoveShare(shareRepo)(account, thisShare);
    for (final f in unsharingFiles) {
      _log.info("[call] Unsharing '${f.path}'");
      try {
        final shares = await ListShare(shareRepo)(account, f);
        final share =
            shares.firstWhere((element) => element.shareWith == shareWith);
        await RemoveShare(shareRepo)(account, share);
      } catch (e, stackTrace) {
        _log.severe(
            "[call] Failed while RemoveShare: ${f.path}", e, stackTrace);
        onUnshareFileFailed?.call(f);
      }
    }
  }

  /// Return list of files shared with [shareWith] in [album] but not in
  /// [others]
  Future<List<File>> _getExclusiveSharedFiles(Account account, Album album,
      List<Album> others, String shareWith) async {
    var files = AlbumStaticProvider.of(album)
        .items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .toList();
    for (final a in others) {
      // filter out files in a
      files = files
          .where((f) => !AlbumStaticProvider.of(a)
              .items
              .whereType<AlbumFileItem>()
              .any((element) => element.file.path == f.path))
          .toList();
    }
    return files;
  }

  final ShareRepo shareRepo;
  final FileRepo fileRepo;
  final AlbumRepo albumRepo;

  static final _log =
      Logger("use_case.unshare_album_with_user.UnshareAlbumWithUser");
}
