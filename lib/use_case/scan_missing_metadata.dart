import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/use_case/scan_dir.dart';

class ScanMissingMetadata {
  ScanMissingMetadata(this.fileRepo);

  /// List all files that support metadata but yet having one under a dir
  /// recursively
  ///
  /// Dirs with a .nomedia/.noimage file will be ignored. The returned stream
  /// would emit either File data or an exception
  Stream<dynamic> call(Account account, File root) async* {
    final dataStream = ScanDir(fileRepo)(account, root);
    await for (final d in dataStream) {
      if (d is Exception || d is Error) {
        yield d;
        continue;
      }
      final missingMetadata = (d as List<File>).where((element) =>
          file_util.isSupportedFormat(element) && element.metadata == null);
      for (final f in missingMetadata) {
        yield f;
      }
    }
  }

  final FileRepo fileRepo;
}
