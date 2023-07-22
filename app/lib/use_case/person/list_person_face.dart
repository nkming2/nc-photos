import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/person/adapter.dart';
import 'package:nc_photos/entity/person_face.dart';

class ListPersonFace {
  const ListPersonFace(this._c);

  Stream<List<PersonFace>> call(Account account, Person person) =>
      PersonAdapter.of(_c, account, person).listFace();

  final DiContainer _c;
}
