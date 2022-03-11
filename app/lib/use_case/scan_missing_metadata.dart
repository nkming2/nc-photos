import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:nc_photos/use_case/scan_dir.dart';

class ScanMissingMetadata {
  ScanMissingMetadata(this.fileRepo);

  /// List all files that support metadata but yet having one under a dir
  ///
  /// The returned stream would emit either File data or ExceptionEvent
  ///
  /// If [isRecursive] is true, [root] and its sub dirs will be listed,
  /// otherwise only [root] will be listed. Default to true
  Stream<dynamic> call(
    Account account,
    File root, {
    bool isRecursive = true,
  }) async* {
    if (isRecursive) {
      yield* _doRecursive(account, root);
    } else {
      yield* _doSingle(account, root);
    }
  }

  Stream<dynamic> _doRecursive(Account account, File root) async* {
    final dataStream = ScanDir(fileRepo)(account, root);
    await for (final d in dataStream) {
      if (d is ExceptionEvent) {
        yield d;
        continue;
      }
      for (final f in (d as List<File>).where(_isMissing)) {
        yield f;
      }
    }
  }

  Stream<dynamic> _doSingle(Account account, File root) async* {
    final files = await Ls(fileRepo)(account, root);
    for (final f in files.where(_isMissing)) {
      yield f;
    }
  }

  bool _isMissing(File file) =>
      file_util.isSupportedImageFormat(file) && file.metadata == null;

  final FileRepo fileRepo;
}
