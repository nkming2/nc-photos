import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/face_recognition_person.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/person/content_provider/face_recognition.dart';

class PersonBuilder {
  static Person byFaceRecognitionPerson(
      Account account, FaceRecognitionPerson person) {
    return Person(
      name: person.name,
      contentProvider: PersonFaceRecognitionProvider(
        account: account,
        person: person,
      ),
    );
  }
}
