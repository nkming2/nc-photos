import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/iterable_extension.dart';
import 'package:np_codegen/np_codegen.dart';

part 'find_file_descriptor.g.dart';

@npLog
class FindFileDescriptor {
  FindFileDescriptor(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// Find list of files in the DB by [fileIds]
  ///
  /// If an id is not found, [onFileNotFound] will be called. If
  /// [onFileNotFound] is null, a [StateError] will be thrown
  Future<List<FileDescriptor>> call(
    Account account,
    List<int> fileIds, {
    void Function(int fileId)? onFileNotFound,
  }) async {
    _log.info("[call] fileIds: ${fileIds.toReadableString()}");
    final dbFiles = await _c.sqliteDb.use((db) async {
      return await db.fileDescriptorsByFileIds(
          sql.ByAccount.app(account), fileIds);
    });
    final files = dbFiles.convertToAppFileDescriptor(account);
    final fileMap = <int, FileDescriptor>{};
    for (final f in files) {
      fileMap[f.fdId] = f;
    }

    final results = <FileDescriptor>[];
    for (final id in fileIds) {
      final f = fileMap[id];
      if (f == null) {
        if (onFileNotFound == null) {
          throw StateError("File ID not found: $id");
        } else {
          onFileNotFound(id);
        }
      } else {
        results.add(f);
      }
    }
    return results;
  }

  final DiContainer _c;
}
