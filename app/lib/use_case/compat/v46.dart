import 'package:logging/logging.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:np_codegen/np_codegen.dart';

part 'v46.g.dart';

@npLog
class CompatV46 {
  static Future<void> insertDbAccounts(Pref pref, sql.SqliteDb sqliteDb) async {
    _log.info("[insertDbAccounts] Insert current accounts to Sqlite database");
    await sqliteDb.use((db) async {
      final accounts = pref.getAccounts3Or([]);
      for (final a in accounts) {
        _log.info("[insertDbAccounts] Insert account to Sqlite db: $a");
        await db.insertAccountOf(a);
      }
    });
  }

  static final _log = _$CompatV46NpLog.log;
}
