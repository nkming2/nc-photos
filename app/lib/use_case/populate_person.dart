import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:np_codegen/np_codegen.dart';

part 'populate_person.g.dart';

@npLog
class PopulatePerson {
  PopulatePerson(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// Return a list of files of the faces
  Future<List<File>> call(Account account, List<Face> faces) async {
    final fileIds = faces.map((f) => f.fileId).toList();
    final dbFiles = await _c.sqliteDb.use((db) async {
      return await db.completeFilesByFileIds(fileIds, appAccount: account);
    });
    final files = await dbFiles.convertToAppFile(account);
    final fileMap = Map.fromEntries(files.map((f) => MapEntry(f.fileId, f)));
    return faces
        .map((f) {
          final file = fileMap[f.fileId];
          if (file == null) {
            _log.warning(
                "[call] File doesn't exist in DB, removed?: ${f.fileId}");
          }
          return file;
        })
        .whereNotNull()
        .toList();
  }

  final DiContainer _c;
}
