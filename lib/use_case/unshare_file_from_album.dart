import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/remove_share.dart';

class UnshareFileFromAlbum {
  UnshareFileFromAlbum(this._c)
      : assert(require(_c)),
        assert(ListShare.require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.albumRepo) &&
      DiContainer.has(c, DiType.fileRepo) &&
      DiContainer.has(c, DiType.shareRepo);

  /// Remove file shares created for an album
  ///
  /// Since a file may live in several albums, this will check across all albums
  /// and only remove shares exclusive to [album]
  Future<void> call(
    Account account,
    Album album,
    List<File> files,
    List<CiString> unshareWith, {
    void Function(Share)? onUnshareFileFailed,
  }) async {
    _log.info(
        "[call] Unshare ${files.length} files from album '${album.name}' with ${unshareWith.length} users");
    // list albums with shares identical to any element in [unshareWith]
    final otherAlbums = await ListAlbum(_c.fileRepo, _c.albumRepo)(account)
        .where((event) => event is Album)
        .cast<Album>()
        .where((a) =>
            !a.albumFile!.compareServerIdentity(album.albumFile!) &&
            a.provider is AlbumStaticProvider &&
            a.shares?.any((s) => unshareWith.contains(s.userId)) == true)
        .toList();

    // look for shares that are exclusive to this album
    final exclusiveShares = <Share>[];
    for (final f in files) {
      try {
        final shares = await ListShare(_c)(account, f);
        exclusiveShares.addAll(
            shares.where((element) => unshareWith.contains(element.shareWith)));
      } catch (e, stackTrace) {
        _log.severe("[call] Failed while ListShare: '${logFilename(f.path)}'",
            e, stackTrace);
      }
    }
    _log.fine("[call] Pre-filter shares: $exclusiveShares");
    for (final a in otherAlbums) {
      // check if the album is shared with the same users
      final sharesOfInterest =
          a.shares?.where((as) => unshareWith.contains(as.userId)).toList();
      if (sharesOfInterest == null || sharesOfInterest.isEmpty) {
        continue;
      }
      final albumFiles = AlbumStaticProvider.of(a)
          .items
          .whereType<AlbumFileItem>()
          .map((e) => e.file)
          .toList();
      // remove files shared as part of this other shared album
      exclusiveShares.removeWhere((s) =>
          sharesOfInterest.any((i) => i.userId == s.shareWith) &&
          albumFiles.any((f) => f.fileId == s.itemSource));
    }
    _log.fine("[call] Post-filter shares: $exclusiveShares");

    // unshare them
    await _unshare(account, exclusiveShares, onUnshareFileFailed);
  }

  Future<void> _unshare(Account account, List<Share> shares,
      void Function(Share)? onUnshareFileFailed) async {
    for (final s in shares) {
      try {
        await RemoveShare(_c.shareRepo)(account, s);
      } catch (e, stackTrace) {
        _log.severe(
            "[_unshare] Failed while RemoveShare: ${s.path}", e, stackTrace);
        onUnshareFileFailed?.call(s);
      }
    }
  }

  final DiContainer _c;

  static final _log =
      Logger("use_case.unshare_file_from_album.UnshareFileFromAlbum");
}
