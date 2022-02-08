import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/tag.dart';

class ListTag {
  ListTag(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.tagRepo);

  /// List all tags
  Future<List<Tag>> call(Account account) => _c.tagRepo.list(account);

  final DiContainer _c;
}
