import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/ls.dart';
import 'package:tuple/tuple.dart';

class ListPendingSharedAlbum {
  ListPendingSharedAlbum(this.fileRepo, this.albumRepo);

  /// Return shared albums that are known to us (in pending dir) but not added
  /// to the user library
  ///
  /// The returned stream would emit either Album data or a tuple of exception
  /// and stacktrace
  Stream<dynamic> call(Account account) async* {
    List<File> ls;
    try {
      ls = await Ls(fileRepo)(
          account,
          File(
            path: remote_storage_util.getRemotePendingSharedAlbumsDir(account),
          ));
    } catch (e, stacktrace) {
      if (e is ApiException && e.response.statusCode == 404) {
        // no albums
        return;
      }
      yield Tuple2(e, stacktrace);
      return;
    }
    final albumFiles =
        ls.where((element) => element.isCollection != true).toList();
    for (final f in albumFiles) {
      try {
        yield await albumRepo.get(account, f);
      } catch (e, stacktrace) {
        yield Tuple2(e, stacktrace);
      }
    }
    try {
      albumRepo.cleanUp(
          account,
          remote_storage_util.getRemotePendingSharedAlbumsDir(account),
          albumFiles);
    } catch (e, stacktrace) {
      // not important, log and ignore
      _log.shout("[_call] Failed while cleanUp", e, stacktrace);
    }
  }

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;

  static final _log =
      Logger("user_case.list_pending_shared_album.ListPendingSharedAlbum");
}
