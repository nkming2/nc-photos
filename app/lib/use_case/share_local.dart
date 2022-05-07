import 'package:logging/logging.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/local_file.dart';

class ShareLocal {
  ShareLocal(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.localFileRepo);

  Future<void> call(
    List<LocalFile> files, {
    LocalFileOnFailureListener? onFailure,
  }) async {
    var count = files.length;
    await _c.localFileRepo.shareFiles(files, onFailure: (f, e, stackTrace) {
      --count;
      onFailure?.call(f, e, stackTrace);
    });
    _log.info("[call] Shared $count files successfully");
  }

  final DiContainer _c;

  static final _log = Logger("use_case.share_local.ShareLocal");
}
