import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/face_recognition_person.dart';

class ListFaceRecognitionPerson {
  const ListFaceRecognitionPerson(this._c);

  /// List all [FaceRecognitionPerson]s belonging to [account]
  Stream<List<FaceRecognitionPerson>> call(Account account) =>
      _c.faceRecognitionPersonRepo.getPersons(account);

  final DiContainer _c;
}
