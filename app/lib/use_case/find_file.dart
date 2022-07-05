import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/iterable_extension.dart';

class FindFile {
  FindFile(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// Find list of files in the DB by [fileIds]
  ///
  /// If an id is not found, [onFileNotFound] will be called. If
  /// [onFileNotFound] is null, a [StateError] will be thrown
  Future<List<File>> call(
    Account account,
    List<int> fileIds, {
    void Function(int fileId)? onFileNotFound,
  }) async {
    _log.info("[call] fileIds: ${fileIds.toReadableString()}");
    final dbFiles = await _c.sqliteDb.use((db) async {
      return await db.completeFilesByFileIds(fileIds, appAccount: account);
    });
    final files = await dbFiles.convertToAppFile(account);
    final fileMap = <int, File>{};
    for (final f in files) {
      fileMap[f.fileId!] = f;
    }

    return () sync* {
      for (final id in fileIds) {
        final f = fileMap[id];
        if (f == null) {
          if (onFileNotFound == null) {
            throw StateError("File ID not found: $id");
          } else {
            onFileNotFound(id);
          }
        } else {
          yield fileMap[id]!;
        }
      }
    }()
        .toList();
  }

  final DiContainer _c;

  static final _log = Logger("use_case.find_file.FindFile");
}
