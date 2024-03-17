import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';

part 'archive_file.g.dart';

class ArchiveFile {
  ArchiveFile(DiContainer c) : _op = _SetArchiveFile(c);

  /// Archive list of [files] and return the archived count
  Future<int> call(
    Account account,
    List<File> files, {
    ErrorWithValueHandler<File>? onError,
  }) =>
      _op(account, files, true, onError: onError);

  final _SetArchiveFile _op;
}

class UnarchiveFile {
  UnarchiveFile(DiContainer c) : _op = _SetArchiveFile(c);

  /// Unarchive list of [files] and return the unarchived count
  Future<int> call(
    Account account,
    List<File> files, {
    ErrorWithValueHandler<File>? onError,
  }) =>
      _op(account, files, false, onError: onError);

  final _SetArchiveFile _op;
}

@npLog
class _SetArchiveFile {
  _SetArchiveFile(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.fileRepo);

  /// Archive list of [files] and return the archived count
  Future<int> call(
    Account account,
    List<File> files,
    bool flag, {
    ErrorWithValueHandler<File>? onError,
  }) async {
    var count = 0;
    for (final f in files) {
      try {
        await UpdateProperty(_c).updateIsArchived(account, f, flag);
        ++count;
      } catch (e, stackTrace) {
        _log.severe(
          "[call] Failed while UpdateProperty: ${logFilename(f.strippedPath)}",
          e,
          stackTrace,
        );
        onError?.call(f, e, stackTrace);
      }
    }
    return count;
  }

  final DiContainer _c;
}
