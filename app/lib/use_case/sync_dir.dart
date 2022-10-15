import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:tuple/tuple.dart';

class SyncDir {
  SyncDir(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.fileRepoRemote) &&
      DiContainer.has(c, DiType.sqliteDb) &&
      DiContainer.has(c, DiType.touchManager);

  /// Sync local SQLite DB with remote content
  ///
  /// Return true if some of the files have changed
  Future<bool> call(
    Account account,
    String dirPath, {
    bool isRecursive = true,
  }) async {
    final dirCache = await _queryAllSubDirEtags(account, dirPath);
    final remoteRoot =
        await LsSingleFile(_c.withRemoteFileRepo())(account, dirPath);
    return await _syncDir(account, remoteRoot, dirCache,
        isRecursive: isRecursive);
  }

  Future<bool> _syncDir(
    Account account,
    File remoteDir,
    Map<int, String> dirCache, {
    required bool isRecursive,
  }) async {
    final status = await _checkContentUpdated(account, remoteDir, dirCache);
    if (!status.item1) {
      _log.finer("[_syncDir] Dir unchanged: ${remoteDir.path}");
      return false;
    }
    _log.info("[_syncDir] Dir changed: ${remoteDir.path}");

    final children = await FileCachedDataSource(_c, shouldCheckCache: true)
        .sync(account, remoteDir, remoteTouchEtag: status.item2);
    if (!isRecursive) {
      return true;
    }
    for (final d in children.where((c) =>
        c.isCollection == true &&
        !remoteDir.compareServerIdentity(c) &&
        !c.path.endsWith(remote_storage_util.getRemoteStorageDir(account)))) {
      try {
        await _syncDir(account, d, dirCache, isRecursive: isRecursive);
      } catch (e, stackTrace) {
        _log.severe("[_syncDir] Failed while _syncDir: ${logFilename(d.path)}",
            e, stackTrace);
      }
    }
    return true;
  }

  Future<Tuple2<bool, String?>> _checkContentUpdated(
      Account account, File remoteDir, Map<int, String> dirCache) async {
    String? touchResult;
    try {
      touchResult = await _c.touchManager.checkTouchEtag(account, remoteDir);
      if (touchResult == null &&
          dirCache[remoteDir.fileId!] == remoteDir.etag!) {
        return const Tuple2(false, null);
      }
    } catch (e, stackTrace) {
      _log.severe("[_isContentUpdated] Uncaught exception", e, stackTrace);
    }
    return Tuple2(true, touchResult);
  }

  Future<Map<int, String>> _queryAllSubDirEtags(
      Account account, String dirPath) async {
    final dir = File(path: dirPath);
    return await _c.sqliteDb.use((db) async {
      final query = db.queryFiles().run((q) {
        q
          ..setQueryMode(sql.FilesQueryMode.expression,
              expressions: [db.files.fileId, db.files.etag])
          ..setAppAccount(account);
        if (dir.strippedPathWithEmpty.isNotEmpty) {
          q.byOrRelativePathPattern("${dir.strippedPathWithEmpty}/%");
        }
        return q.build();
      });
      query.where(db.files.isCollection.equals(true));
      return Map.fromEntries(await query
          .map(
              (r) => MapEntry(r.read(db.files.fileId)!, r.read(db.files.etag)!))
          .get());
    });
  }

  final DiContainer _c;

  static final _log = Logger("use_case.sync_dir.SyncDir");
}
