import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/person.dart';

class ListFace {
  ListFace(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.faceRepo);

  Future<List<Face>> call(Account account, Person person) =>
      _c.faceRepo.list(account, person);

  final DiContainer _c;
}
