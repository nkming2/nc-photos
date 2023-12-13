import 'package:np_db/np_db.dart';

class CompatV55 {
  static Future<void> migrateDb(
    NpDb db, {
    void Function(int current, int count)? onProgress,
  }) {
    return db.migrateV55(onProgress);
  }
}
