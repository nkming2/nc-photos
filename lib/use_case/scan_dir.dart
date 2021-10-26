import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/ls.dart';

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
      for (final i in items.where((element) =>
          element.isCollection == true &&
          !element.path
              .endsWith(remote_storage_util.getRemoteStorageDir(account)))) {
        yield* this(account, i);
      }
    } on CacheNotFoundException catch (e, stackTrace) {
      _log.info("[call] Cache not found");
      yield ExceptionEvent(e, stackTrace);
    } catch (e, stackTrace) {
      _log.shout(
          "[call] Failed while listing dir" +
              (shouldLogFileName ? ": ${root.path}" : ""),
          e,
          stackTrace);
      // for some reason exception thrown here can't be caught outside
      // rethrow;
      yield ExceptionEvent(e, stackTrace);
    }
  }

  /// Return if this dir should be ignored in a scan op based on files under
  /// this dir
  static bool _shouldScanIgnoreDir(Iterable<File> files) {
    return files.any((element) {
      final basename = element.filename;
      return basename == ".nomedia" || basename == ".noimage";
    });
  }

  final FileRepo fileRepo;

  static final _log = Logger("use_case.scan_dir.ScanDir");
}
