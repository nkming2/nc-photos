import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/use_case/list_shared_album.dart';
import 'package:nc_photos/use_case/remove_share.dart';
import 'package:nc_photos/use_case/unshare_file_from_album.dart';

class UnshareAlbumWithUser {
  UnshareAlbumWithUser(this.shareRepo, this.fileRepo, this.albumRepo);

  Future<void> call(
    Account account,
    Album album,
    String shareWith, {
    void Function(Share)? onUnshareFileFailed,
  }) async {
    assert(album.provider is AlbumStaticProvider);
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    final sharedItems =
        await ListSharedAlbum(shareRepo, fileRepo, albumRepo)(account);
    final thisShare = sharedItems
        .firstWhere((element) =>
            element.album.albumFile!.compareServerIdentity(album.albumFile!) &&
            element.share.shareWith == shareWith)
        .share;
    await RemoveShare(shareRepo)(account, thisShare);

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
      listSharedAlbumResults: sharedItems,
      onUnshareFileFailed: onUnshareFileFailed,
    );
  }

  final ShareRepo shareRepo;
  final FileRepo fileRepo;
  final AlbumRepo albumRepo;
}
