import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/use_case/find_file.dart';

/// List all shares from a given file
class ListShare {
  ListShare(this._c)
      : assert(require(_c)),
        assert(FindFile.require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.shareRepo);

  Future<List<Share>> call(
    Account account,
    File file, {
    bool? isIncludeReshare,
  }) async {
    try {
      if (file_util.getUserDirName(file) != account.userId) {
        file = (await FindFile(_c)(account, [file.fileId!])).first;
      }
    } catch (_) {
      // file not found
      _log.warning("[call] File not found in db: ${logFilename(file.path)}");
    }
    return _c.shareRepo.list(
      account,
      file,
      isIncludeReshare: isIncludeReshare,
    );
  }

  final DiContainer _c;

  static final _log = Logger("use_case.list_share.ListShare");
}
