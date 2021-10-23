import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/list_dir_share.dart';
import 'package:nc_photos/use_case/ls.dart';

class ListSharedAlbumItem {
  const ListSharedAlbumItem(this.share, this.album);

  final Share share;
  final Album album;
}

class ListSharedAlbum {
  const ListSharedAlbum(this.shareRepo, this.fileRepo, this.albumRepo);

  /// List albums that are currently shared by you
  ///
  /// If [whereShareWith] is not null, only shares sharing with [whereShareWith]
  /// will be returned.
  Future<List<ListSharedAlbumItem>> call(
    Account account, {
    String? whereShareWith,
  }) async {
    final shareItems = await ListDirShare(shareRepo)(
        account, File(path: remote_storage_util.getRemoteAlbumsDir(account)));
    final files = await Ls(fileRepo)(
      account,
      File(path: remote_storage_util.getRemoteAlbumsDir(account)),
    );

    final products = <ListSharedAlbumItem>[];
    for (final si in shareItems) {
      // find the file
      final albumFile =
          files.firstWhere((element) => element.compareServerIdentity(si.file));
      final album = await albumRepo.get(
        account,
        albumFile,
      );
      for (final s in si.shares) {
        if (whereShareWith != null && s.shareWith != whereShareWith) {
          continue;
        }
        products.add(ListSharedAlbumItem(s, album));
      }
    }
    return products;
  }

  final ShareRepo shareRepo;
  final FileRepo fileRepo;
  final AlbumRepo albumRepo;
}
