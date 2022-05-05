import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/local_file.dart';

class ScanLocalDir {
  ScanLocalDir(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.localFileRepo);

  /// List all files under a local dir recursively
  Future<List<LocalFile>> call(String relativePath) async {
    final files = await _c.localFileRepo.listDir(relativePath);
    return files
        .where((f) => file_util.isSupportedImageMime(f.mime ?? ""))
        .toList();
  }

  final DiContainer _c;
}
