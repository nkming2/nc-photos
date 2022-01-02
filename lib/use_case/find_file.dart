import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';

class FindFile {
  FindFile(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.appDb);

  /// Find the [File] in the DB by [fileId]
  Future<File> call(Account account, int fileId) async {
    final dbItem = await _c.appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.file2StoreName);
      return await store
          .getObject(AppDbFile2Entry.toPrimaryKey(account, fileId)) as Map?;
    });
    if (dbItem == null) {
      throw StateError("File ID not found: $fileId");
    }
    final dbEntry = AppDbFile2Entry.fromJson(dbItem.cast<String, dynamic>());
    return dbEntry.file;
  }

  final DiContainer _c;
}
