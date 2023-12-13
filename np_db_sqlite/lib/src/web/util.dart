import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:http/http.dart' as http;
import 'package:np_db_sqlite/src/database.dart';
import 'package:sqlite3/wasm.dart';

Future<Map<String, dynamic>> getSqliteConnectionArgs() async => {};

QueryExecutor openSqliteConnectionWithArgs(Map<String, dynamic> args) =>
    openSqliteConnection();

QueryExecutor openSqliteConnection() {
  return LazyDatabase(() async {
    // Load wasm bundle
    final response = await http.get(Uri.parse("sqlite3.wasm"));
    // Create a virtual file system backed by IndexedDb with everything in
    // `/drift/my_app/` being persisted.
    final fs = await IndexedDbFileSystem.open(dbName: "nc-photos");
    final sqlite3 = await WasmSqlite3.load(
      response.bodyBytes,
      SqliteEnvironment(fileSystem: fs),
    );

    // Then, open a database inside that persisted folder.
    return WasmDatabase(
      sqlite3: sqlite3,
      path: "/drift/nc-photos/app.db",
      fileSystem: fs,
      // logStatements: true,
    );
  });
}

Future<void> applyWorkaroundToOpenSqlite3OnOldAndroidVersions() async {
  // unnecessary on web
}

Future<File> exportSqliteDb(SqliteDb db, Directory dir) async {
  throw UnimplementedError();
}
