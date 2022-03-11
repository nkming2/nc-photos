import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/person.dart';

class Face with EquatableMixin {
  const Face({
    required this.id,
    required this.fileId,
  });

  @override
  toString() {
    return "$runtimeType {"
        "id: '$id', "
        "fileId: '$fileId', "
        "}";
  }

  @override
  get props => [
        id,
        fileId,
      ];

  final int id;
  final int fileId;
}

class FaceRepo {
  const FaceRepo(this.dataSrc);

  /// See [FaceDataSource.list]
  Future<List<Face>> list(Account account, Person person) =>
      dataSrc.list(account, person);

  final FaceDataSource dataSrc;
}

abstract class FaceDataSource {
  /// List all faces associated to [person]
  Future<List<Face>> list(Account account, Person person);
}
