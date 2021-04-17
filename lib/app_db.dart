import 'dart:async';

import 'package:idb_shim/idb.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:synchronized/synchronized.dart';

class AppDb {
  static const dbName = "app.db";
  static const fileStoreName = "files";
  static const albumStoreName = "albums";

  /// Run [fn] with an opened database instance
  ///
  /// This function guarantees that:
  /// 1) Database is always closed after [fn] exits, even with an error
  /// 2) Only at most 1 database instance being opened at any time
  static Future<T> use<T>(FutureOr<T> Function(Database) fn) async {
    // make sure only one client is opening the db
    return await _lock.synchronized(() async {
      final db = await _open();
      try {
        return await fn(db);
      } finally {
        db.close();
      }
    });
  }

  /// Open the database
  static Future<Database> _open() async {
    final dbFactory = platform.getDbFactory();
    return dbFactory.open(dbName, version: 1, onUpgradeNeeded: (event) {
      final db = event.database;
      if (event.oldVersion < 1) {
        db.createObjectStore(fileStoreName);
        db.createObjectStore(albumStoreName);
      }
    });
  }

  static final _lock = Lock(reentrant: true);
}
