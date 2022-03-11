import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/compat/v15.dart';
import 'package:nc_photos/use_case/compat/v25.dart';
import 'package:nc_photos/use_case/ls.dart';

class ListAlbum {
  ListAlbum(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.albumRepo) &&
      DiContainer.has(c, DiType.fileRepo);

  /// List all albums associated with [account]
  ///
  /// The returned stream would emit either [Album] or [ExceptionEvent]
  Stream<dynamic> call(Account account) async* {
    bool hasAlbum = false;
    await for (final result in _call(account)) {
      hasAlbum = true;
      yield result;
    }
    if (!hasAlbum) {
      if (await CompatV15.migrateAlbumFiles(account, _c.fileRepo)) {
        // migrated, try again
        yield* _call(account);
      }
    }
  }

  Stream<dynamic> _call(Account account) async* {
    List<File> ls;
    try {
      ls = await Ls(_c.fileRepo)(
          account,
          File(
            path: remote_storage_util.getRemoteAlbumsDir(account),
          ));
    } catch (e, stackTrace) {
      if (e is ApiException && e.response.statusCode == 404) {
        // no albums
        return;
      }
      yield ExceptionEvent(e, stackTrace);
      return;
    }
    final albumFiles =
        ls.where((element) => element.isCollection != true).toList();
    for (var i = 0; i < albumFiles.length; ++i) {
      var f = albumFiles[i];
      try {
        if (CompatV25.isAlbumFileNeedMigration(f)) {
          f = await CompatV25.migrateAlbumFile(_c, account, f);
        }
        albumFiles[i] = f;
        yield await _c.albumRepo.get(account, f);
      } catch (e, stackTrace) {
        yield ExceptionEvent(e, stackTrace);
      }
    }
    try {
      _c.albumRepo.cleanUp(
          account, remote_storage_util.getRemoteAlbumsDir(account), albumFiles);
    } catch (e, stacktrace) {
      // not important, log and ignore
      _log.shout("[_call] Failed while cleanUp", e, stacktrace);
    }
  }

  final DiContainer _c;

  static final _log = Logger("use_case.list_album.ListAlbum");
}
