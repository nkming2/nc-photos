import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:path/path.dart' as path;

class ScanDir {
  ScanDir(this.fileRepo);

  /// List all files under a dir recursively
  ///
  /// Dirs with a .nomedia/.noimage file will be ignored. The returned stream
  /// would emit either List<File> data or an exception
  Stream<dynamic> call(Account account, File root) async* {
    try {
      final items = await Ls(fileRepo)(account, root);
      if (_shouldScanIgnoreDir(items)) {
        return;
      }
      yield items.where((element) => element.isCollection != true).toList();
      for (final i in items.where((element) => element.isCollection == true)) {
        yield* this(account, i);
      }
    } catch (e, stacktrace) {
      _log.severe("[call] Failed scanning \"${root.path}\"", e, stacktrace);
      // for some reason exception thrown here can't be caught outside
      // rethrow;
      yield e;
    }
  }

  /// Return if this dir should be ignored in a scan op based on files under
  /// this dir
  static bool _shouldScanIgnoreDir(Iterable<File> files) {
    return files.any((element) {
      final basename = path.basename(element.path);
      return basename == ".nomedia" || basename == ".noimage";
    });
  }

  final FileRepo fileRepo;

  static final _log = Logger("use_case.scan_dir.ScanDir");
}
