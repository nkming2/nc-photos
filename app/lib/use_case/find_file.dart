import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';

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
    final dbItems = await _c.appDb.use(
      (db) => db.transaction(AppDb.file2StoreName, idbModeReadOnly),
      (transaction) async {
        final fileStore = transaction.objectStore(AppDb.file2StoreName);
        return await Future.wait(fileIds.map((id) =>
            fileStore.getObject(AppDbFile2Entry.toPrimaryKey(account, id))));
      },
    );
    final fileMap = await compute(_covertFileMap, dbItems);
    final files = <File>[];
    for (final id in fileIds) {
      final f = fileMap[id];
      if (f == null) {
        if (onFileNotFound == null) {
          throw StateError("File ID not found: $id");
        } else {
          onFileNotFound(id);
        }
      } else {
        files.add(f);
      }
    }
    return files;
  }

  final DiContainer _c;
}

Map<int, File> _covertFileMap(List<Object?> dbItems) {
  return Map.fromEntries(dbItems
      .whereType<Map>()
      .map((j) => AppDbFile2Entry.fromJson(j.cast<String, dynamic>()).file)
      .map((f) => MapEntry(f.fileId!, f)));
}
