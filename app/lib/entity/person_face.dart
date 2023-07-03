import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:to_string/to_string.dart';

part 'person_face.g.dart';

/// A file with the face of a person
abstract class PersonFace {
  const PersonFace();

  FileDescriptor get file;
}

/// The basic form of [PersonFace]
@toString
class BasicPersonFace implements PersonFace {
  const BasicPersonFace(this.file);

  @override
  String toString() => _$toString();

  @override
  final FileDescriptor file;
}
