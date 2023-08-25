import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/face_recognition_person.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/use_case/face_recognition_person/list_face_recognition_person.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_collection/np_collection.dart';

part 'sync_face_recognition_person.g.dart';

@npLog
class SyncFaceRecognitionPerson {
  const SyncFaceRecognitionPerson(this._c);

  /// Sync people in cache db with remote server
  ///
  /// Return if any people were updated
  Future<bool> call(Account account) async {
    _log.info("[call] Sync people with remote");
    int personSorter(FaceRecognitionPerson a, FaceRecognitionPerson b) =>
        a.name.compareTo(b.name);
    late final List<FaceRecognitionPerson> remote;
    try {
      remote = (await ListFaceRecognitionPerson(_c.withRemoteRepo())(account)
          .last)
        ..sort(personSorter);
    } catch (e) {
      if (e is ApiException && e.response.statusCode == 404) {
        // face recognition app probably not installed, ignore
        _log.info("[call] Face Recognition app not installed");
        return false;
      }
      rethrow;
    }
    final cache = (await ListFaceRecognitionPerson(_c.withLocalRepo())(account)
        .last)
      ..sort(personSorter);
    final diff = getDiffWith(cache, remote, personSorter);
    final inserts = diff.onlyInB;
    _log.info("[call] New people: ${inserts.toReadableString()}");
    final deletes = diff.onlyInA;
    _log.info("[call] Removed people: ${deletes.toReadableString()}");
    final updates = remote.where((r) {
      final c = cache.firstWhereOrNull((c) => c.name == r.name);
      return c != null && c != r;
    }).toList();
    _log.info("[call] Updated people: ${updates.toReadableString()}");

    if (inserts.isNotEmpty || deletes.isNotEmpty || updates.isNotEmpty) {
      await _c.sqliteDb.use((db) async {
        final dbAccount = await db.accountOf(account);
        await db.batch((batch) {
          for (final d in deletes) {
            batch.deleteWhere(
              db.faceRecognitionPersons,
              (sql.$FaceRecognitionPersonsTable p) =>
                  p.account.equals(dbAccount.rowId) & p.name.equals(d.name),
            );
          }
          for (final u in updates) {
            batch.update(
              db.faceRecognitionPersons,
              sql.FaceRecognitionPersonsCompanion(
                name: sql.Value(u.name),
                thumbFaceId: sql.Value(u.thumbFaceId),
                count: sql.Value(u.count),
              ),
              where: (sql.$FaceRecognitionPersonsTable p) =>
                  p.account.equals(dbAccount.rowId) & p.name.equals(u.name),
            );
          }
          for (final i in inserts) {
            batch.insert(
              db.faceRecognitionPersons,
              SqliteFaceRecognitionPersonConverter.toSql(dbAccount, i),
              mode: sql.InsertMode.insertOrIgnore,
            );
          }
        });
      });
      return true;
    } else {
      return false;
    }
  }

  final DiContainer _c;
}
