import 'package:logging/logging.dart';
import 'package:nc_photos/db/entity_converter.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_db/np_db.dart';

part 'v46.g.dart';

@npLog
class CompatV46 {
  static Future<void> insertDbAccounts(Pref pref, NpDb db) async {
    _log.info("[insertDbAccounts] Insert current accounts to Sqlite database");
    final accounts = pref.getAccounts3Or([]);
    await db.addAccounts(accounts.toDb());
  }

  static final _log = _$CompatV46NpLog.log;
}
