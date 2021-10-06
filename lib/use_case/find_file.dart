import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;

class FindFile {
  /// Find the [File] in the DB by [fileId]
  Future<File> call(Account account, int fileId) async {
    return await AppDb.use((db) async {
      final transaction =
          db.transaction(AppDb.fileDbStoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.fileDbStoreName);
      final index = store.index(AppDbFileDbEntry.indexName);
      final List dbItems = await index
          .getAll(AppDbFileDbEntry.toNamespacedFileId(account, fileId));

      // find the one owned by us
      final dbItem = dbItems.firstWhere((element) {
        final e = AppDbFileDbEntry.fromJson(element.cast<String, dynamic>());
        return file_util.getUserDirName(e.file) == account.username;
      });
      final dbEntry = AppDbFileDbEntry.fromJson(dbItem.cast<String, dynamic>());
      return dbEntry.file;
    });
  }
}
