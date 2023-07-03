import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/person/builder.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/use_case/face_recognition_person/list_face_recognition_person.dart';
import 'package:np_codegen/np_codegen.dart';

part 'list_person.g.dart';

@npLog
class ListPerson {
  const ListPerson(this._c);

  Stream<List<Person>> call(Account account, AccountPref accountPref) async* {
    if (accountPref.isEnableFaceRecognitionAppOr()) {
      try {
        await for (final results in ListFaceRecognitionPerson(_c)(account)) {
          yield results
              .map((e) => PersonBuilder.byFaceRecognitionPerson(account, e))
              .toList();
        }
      } catch (e, stackTrace) {
        // not installed?
        _log.severe(
            "[call] Failed while ListFaceRecognitionPerson", e, stackTrace);
      }
    }
  }

  final DiContainer _c;
}
