import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:path/path.dart' as path_lib;

class ScanDirOffline {
  ScanDirOffline(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.appDb);

  /// List all files under a dir recursively from the local DB
  ///
  /// Dirs with a .nomedia/.noimage file will be ignored
  Future<List<File>> call(Account account, File root) async {
    final skipDirs = <File>[];
    final files = await _c.appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.file2StoreName);
      final index = store.index(AppDbFile2Entry.strippedPathIndexName);
      final range = KeyRange.bound(
        AppDbFile2Entry.toStrippedPathIndexLowerKeyForDir(account, root),
        AppDbFile2Entry.toStrippedPathIndexUpperKeyForDir(account, root),
      );
      final files = <File>[];
      await for (final f in index
          .openCursor(range: range, autoAdvance: true)
          .map((c) => c.value)
          .cast<Map>()
          .map((e) =>
              AppDbFile2Entry.fromJson(e.cast<String, dynamic>()).file)) {
        if (file_util.isNoMediaMarker(f)) {
          skipDirs.add(File(path: path_lib.dirname(f.path)));
        } else if (file_util.isSupportedFormat(f)) {
          files.add(f);
        }
      }
      return files;
    });

    _log.info(
        "[call] Skip dirs: ${skipDirs.map((d) => d.strippedPath).toReadableString()}");
    if (skipDirs.isEmpty) {
      return files;
    } else {
      return files
          .where((f) => !skipDirs.any((d) => file_util.isUnderDir(f, d)))
          .toList();
    }
  }

  final DiContainer _c;

  static final _log = Logger("use_case.scan_dir_offline.ScanDirOffline");
}
