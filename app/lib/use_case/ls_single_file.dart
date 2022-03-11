import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';

class LsSingleFile {
  LsSingleFile(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.fileRepo);

  Future<File> call(Account account, String path) =>
      _c.fileRepo.listSingle(account, File(path: path));

  final DiContainer _c;
}
