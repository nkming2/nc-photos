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
  Future<List<File>> call(
    Account account,
    File root, {
    bool isOnlySupportedFormat = true,
  }) async {
    return await _c.appDb.use(
      (db) => db.transaction(AppDb.file2StoreName, idbModeReadOnly),
      (transaction) async {
        final store = transaction.objectStore(AppDb.file2StoreName);
        final index = store.index(AppDbFile2Entry.strippedPathIndexName);
        final range = KeyRange.bound(
          AppDbFile2Entry.toStrippedPathIndexLowerKeyForDir(account, root),
          AppDbFile2Entry.toStrippedPathIndexUpperKeyForDir(account, root),
        );
        final product = <File>[];
        await for (final c
            in index.openCursor(range: range, autoAdvance: false)) {
          final e = AppDbFile2Entry.fromJson(
              (c.value as Map).cast<String, dynamic>());
          if (!isOnlySupportedFormat || file_util.isSupportedFormat(e.file)) {
            product.add(e.file);
          }
          c.next();
        }
        return product;
      },
    );
  }

  final DiContainer _c;
}
