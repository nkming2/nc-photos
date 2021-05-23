import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/compat/v15.dart';
import 'package:nc_photos/use_case/ls.dart';

class ListAlbum {
  ListAlbum(this.fileRepo, this.albumRepo);

  /// List all albums associated with [account]
  Future<List<Album>> call(Account account) async {
    final results = await _call(account);
    if (results.isEmpty) {
      if (await CompatV15.migrateAlbumFiles(account, fileRepo)) {
        // migrated
        return await _call(account);
      } else {
        // no need to migrate
        return [];
      }
    } else {
      return results;
    }
  }

  Future<List<Album>> _call(Account account) async {
    try {
      final ls = await Ls(fileRepo)(
          account,
          File(
            path: remote_storage_util.getRemoteAlbumsDir(account),
          ));
      final albumFiles =
          ls.where((element) => element.isCollection != true).toList();
      final albums = <Album>[];
      for (final f in albumFiles) {
        final album = await albumRepo.get(account, f);
        albums.add(album);
      }
      try {
        albumRepo.cleanUp(account, albumFiles);
      } catch (e, stacktrace) {
        // not important, log and ignore
        _log.shout("[_call] Failed while cleanUp", e, stacktrace);
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
