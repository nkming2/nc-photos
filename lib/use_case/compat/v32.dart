import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:nc_photos/type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compatibility helper for v32
class CompatV32 {
  static Future<bool> isPrefNeedMigration() async {
    final pref = await SharedPreferences.getInstance();
    return pref.containsKey("accounts");
  }

  static Future<void> migratePref() async {
    final pref = await SharedPreferences.getInstance();
    final jsons = pref.getStringList("accounts");
    if (jsons == null) {
      return;
    }
    _log.info("[call] Migrate Pref.accounts");
    final newJsons = <JsonObj>[];
    for (final j in jsons) {
      newJsons.add(<String, dynamic>{
        "account": jsonDecode(j),
        "settings": <String, dynamic>{
          "isEnableFaceRecognitionApp": true,
        },
      });
    }
    if (await pref.setStringList(
        "accounts2", newJsons.map((e) => jsonEncode(e)).toList())) {
      _log.info("[call] Migrated ${newJsons.length} accounts");
      await pref.remove("accounts");
    } else {
      _log.severe("[call] Failed while writing pref");
    }
  }

  static final _log = Logger("use_case.compat.v32.CompatV32");
}
