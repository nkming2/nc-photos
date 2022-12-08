import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:to_string/to_string.dart';

part 'face.g.dart';

@toString
class Face with EquatableMixin {
  const Face({
    required this.id,
    required this.fileId,
  });

  @override
  String toString() => _$toString();

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
