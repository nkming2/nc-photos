import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/iterable_extension.dart';

class ScanDirOffline {
  ScanDirOffline(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.appDb);

  /// List all files under a dir recursively from the local DB
  Future<Iterable<File>> call(
    Account account,
    File root, {
    bool isOnlySupportedFormat = true,
  }) async {
    final dbItems = await _c.appDb.use(
      (db) => db.transaction(AppDb.file2StoreName, idbModeReadOnly),
      (transaction) async {
        final store = transaction.objectStore(AppDb.file2StoreName);
        final index = store.index(AppDbFile2Entry.strippedPathIndexName);
        final range = KeyRange.bound(
          AppDbFile2Entry.toStrippedPathIndexLowerKeyForDir(account, root),
          AppDbFile2Entry.toStrippedPathIndexUpperKeyForDir(account, root),
        );
        return await index
            .openCursor(range: range, autoAdvance: false)
            .map((c) {
          final v = c.value as Map;
          c.next();
          return v;
        }).toList();
      },
    );
    final results = await dbItems.computeAll(_covertAppDbFile2Entry);
    if (isOnlySupportedFormat) {
      return results.where((f) => file_util.isSupportedFormat(f));
    } else {
      return results;
    }
  }

  final DiContainer _c;
}

File _covertAppDbFile2Entry(Map json) =>
    AppDbFile2Entry.fromJson(json.cast<String, dynamic>()).file;
