import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:quiver/iterables.dart';

class FindFile {
  FindFile(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.appDb);

  /// Find list of files in the DB by [fileIds]
  ///
  /// If an id is not found, [onFileNotFound] will be called. If
  /// [onFileNotFound] is null, a [StateError] will be thrown
  Future<List<File>> call(
    Account account,
    List<int> fileIds, {
    void Function(int fileId)? onFileNotFound,
  }) async {
    final dbItems = await _c.appDb.use((db) async {
      final transaction = db.transaction(AppDb.file2StoreName, idbModeReadOnly);
      final fileStore = transaction.objectStore(AppDb.file2StoreName);
      return await Future.wait(fileIds.map((id) =>
          fileStore.getObject(AppDbFile2Entry.toPrimaryKey(account, id))));
    });
    final files = <File>[];
    for (final pair in zip([fileIds, dbItems])) {
      final dbItem = pair[1] as Map?;
      if (dbItem == null) {
        if (onFileNotFound == null) {
          throw StateError("File ID not found: ${pair[0]}");
        } else {
          onFileNotFound(pair[0] as int);
        }
      } else {
        final dbEntry =
            AppDbFile2Entry.fromJson(dbItem.cast<String, dynamic>());
        files.add(dbEntry.file);
      }
    }
    return files;
  }

  final DiContainer _c;
}
