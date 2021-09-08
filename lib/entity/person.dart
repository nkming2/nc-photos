import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';

class Face with EquatableMixin {
  Face({
    required this.id,
    required this.fileId,
  });

  @override
  get props => [
        id,
        fileId,
      ];

  final int id;
  final int fileId;
}

class Person with EquatableMixin {
  Person({
    this.name,
    required this.id,
    required this.faces,
  });

  @override
  get props => [
        name,
        id,
        faces,
      ];

  final String? name;
  final int id;
  final List<Face> faces;
}

class PersonRepo {
  const PersonRepo(this.dataSrc);

  /// See [PersonDataSource.list]
  Future<List<Person>> list(Account account) => this.dataSrc.list(account);

  final PersonDataSource dataSrc;
}

abstract class PersonDataSource {
  /// List all people for this account
  Future<List<Person>> list(Account account);
}
