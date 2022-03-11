import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/use_case/find_file.dart';

class ListFavoriteOffline {
  ListFavoriteOffline(this._c)
      : assert(require(_c)),
        assert(FindFile.require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.appDb);

  /// List all favorites for [account] from the local DB
  Future<List<File>> call(Account account) {
    final rootDirs = account.roots
        .map((r) => File(path: file_util.unstripPath(account, r)))
        .toList();
    return _c.appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final fileStore = transaction.objectStore(AppDb.file2StoreName);
      final fileIsFavoriteIndex =
          fileStore.index(AppDbFile2Entry.fileIsFavoriteIndexName);
      return await fileIsFavoriteIndex
          .openCursor(
            key: AppDbFile2Entry.toFileIsFavoriteIndexKey(account, true),
            autoAdvance: true,
          )
          .map((c) => AppDbFile2Entry.fromJson(
              (c.value as Map).cast<String, dynamic>()))
          .map((e) => e.file)
          .where((f) =>
              file_util.isSupportedFormat(f) &&
              rootDirs.any((r) => file_util.isOrUnderDir(f, r)))
          .toList();
    });
  }

  final DiContainer _c;
}
