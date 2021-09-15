import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';

class Person with EquatableMixin {
  Person({
    required this.name,
    required this.thumbFaceId,
    required this.count,
  });

  @override
  toString() {
    return "$runtimeType {"
        "name: '$name', "
        "thumbFaceId: '$thumbFaceId', "
        "count: '$count', "
        "}";
  }

  @override
  get props => [
        name,
        thumbFaceId,
        count,
      ];

  final String name;
  final int thumbFaceId;
  final int count;
}

class PersonRepo {
  const PersonRepo(this.dataSrc);

  /// See [PersonDataSource.list]
  Future<List<Person>> list(Account account) => dataSrc.list(account);

  final PersonDataSource dataSrc;
}

abstract class PersonDataSource {
  /// List all people for this account
  Future<List<Person>> list(Account account);
}
