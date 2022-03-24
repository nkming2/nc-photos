import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;

class ScanDirOffline {
  ScanDirOffline(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.appDb);

  /// List all files under a dir recursively from the local DB
  Future<List<File>> call(Account account, File root) async {
    return await _c.appDb.use(
      (db) => db.transaction(AppDb.file2StoreName, idbModeReadOnly),
      (transaction) async {
        final store = transaction.objectStore(AppDb.file2StoreName);
        final index = store.index(AppDbFile2Entry.strippedPathIndexName);
        final range = KeyRange.bound(
          AppDbFile2Entry.toStrippedPathIndexLowerKeyForDir(account, root),
          AppDbFile2Entry.toStrippedPathIndexUpperKeyForDir(account, root),
        );
        return await index
            .openCursor(range: range, autoAdvance: true)
            .map((c) => c.value)
            .cast<Map>()
            .map(
                (e) => AppDbFile2Entry.fromJson(e.cast<String, dynamic>()).file)
            .where((f) => file_util.isSupportedFormat(f))
            .toList();
      },
    );
  }

  final DiContainer _c;
}
