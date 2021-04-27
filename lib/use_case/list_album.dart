import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/use_case/ls.dart';

class ListAlbum {
  ListAlbum(this.fileRepo, this.albumRepo);

  /// List all albums associated with [account]
  Future<List<Album>> call(Account account) async {
    try {
      final albumFiles = await Ls(fileRepo)(
          account,
          File(
            path: getAlbumFileRoot(account),
          ));
      final albums = <Album>[];
      for (final f in albumFiles) {
        final album = await albumRepo.get(account, f);
        albums.add(album);
      }
      try {
        albumRepo.cleanUp(account, albumFiles);
      } catch (e, stacktrace) {
        // not important, log and ignore
        _log.shout("[call] Failed while cleanUp", e, stacktrace);
      }
      return albums;
    } catch (e) {
      if (e is ApiException && e.response.statusCode == 404) {
        // no albums
        return [];
      }
      rethrow;
    }
  }

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;

  static final _log = Logger("use_case.list_album.ListAlbum");
}
