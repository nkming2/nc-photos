import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';

/// List all shares from a given file
class ListShare {
  ListShare(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.shareRepo);

  Future<List<Share>> call(Account account, File file) =>
      _c.shareRepo.list(account, file);

  final DiContainer _c;
}
