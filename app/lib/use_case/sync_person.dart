import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_converter.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/list_util.dart' as list_util;
import 'package:np_codegen/np_codegen.dart';

part 'sync_person.g.dart';

@npLog
class SyncPerson {
  SyncPerson(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.personRepoRemote) &&
      DiContainer.has(c, DiType.personRepoLocal);

  /// Sync people in cache db with remote server
  Future<void> call(Account account) async {
    _log.info("[call] Sync people with remote");
    late final List<Person> remote;
    try {
      remote = await _c.personRepoRemote.list(account);
    } catch (e) {
      if (e is ApiException && e.response.statusCode == 404) {
        // face recognition app probably not installed, ignore
        _log.info("[call] Face Recognition app not installed");
        return;
      }
      rethrow;
    }
    final cache = await _c.personRepoLocal.list(account);
    int personSorter(Person a, Person b) => a.name.compareTo(b.name);
    final diff = list_util.diffWith<Person>(cache, remote, personSorter);
    final inserts = diff.item1;
    _log.info("[call] New people: ${inserts.toReadableString()}");
    final deletes = diff.item2;
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
              db.persons,
              (sql.$PersonsTable p) =>
                  p.account.equals(dbAccount.rowId) & p.name.equals(d.name),
            );
          }
          for (final u in updates) {
            batch.update(
              db.persons,
              sql.PersonsCompanion(
                name: sql.Value(u.name),
                thumbFaceId: sql.Value(u.thumbFaceId),
                count: sql.Value(u.count),
              ),
              where: (sql.$PersonsTable p) =>
                  p.account.equals(dbAccount.rowId) & p.name.equals(u.name),
            );
          }
          for (final i in inserts) {
            batch.insert(db.persons, SqlitePersonConverter.toSql(dbAccount, i),
                mode: sql.InsertMode.insertOrIgnore);
          }
        });
      });
    }
  }

  final DiContainer _c;
}
