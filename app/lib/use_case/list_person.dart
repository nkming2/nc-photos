import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';

class ListPerson {
  ListPerson(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.personRepo);

  /// List all persons
  Future<List<Person>> call(Account account) => _c.personRepo.list(account);

  final DiContainer _c;
}
