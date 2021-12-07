import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';

/// List all shares by other users from a given file
class ListShareWithMe {
  ListShareWithMe(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.shareRepo);

  Future<List<Share>> call(Account account, File file) =>
      _c.shareRepo.reverseList(account, file);

  final DiContainer _c;
}
