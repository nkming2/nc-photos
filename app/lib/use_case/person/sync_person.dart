import 'dart:async';

import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/use_case/face_recognition_person/sync_face_recognition_person.dart';

class SyncPerson {
  const SyncPerson(this._c);

  /// Sync people in cache db with remote server
  ///
  /// Return if any people were updated
  Future<bool> call(Account account, AccountPref accountPref) async {
    if (accountPref.isEnableFaceRecognitionAppOr()) {
      return SyncFaceRecognitionPerson(_c)(account);
    }
    return false;
  }

  final DiContainer _c;
}
