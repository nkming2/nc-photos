import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/use_case/ls.dart';

class LsTrashbin {
  LsTrashbin(this.fileRepo);

  Future<List<File>> call(Account account) =>
      Ls(fileRepo)(account, File(path: api_util.getTrashbinPath(account)));

  final FileRepo fileRepo;
}
