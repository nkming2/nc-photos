import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
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
  // not supported on web
}

Future<CommonDatabase> openRawSqliteDbFromAsset(
  String assetRelativePath,
  String outputFilename, {
  bool isReadOnly = false,
}) async {
  final response = await http.get(Uri.parse("sqlite3.wasm"));
  final fs = await IndexedDbFileSystem.open(dbName: "nc-photos");
  final sqlite3 = await WasmSqlite3.load(
    response.bodyBytes,
    SqliteEnvironment(fileSystem: fs),
  );

  if (!fs.exists("/app-file/$outputFilename")) {
    // copy file from assets
    final blob = await rootBundle.load("assets/$assetRelativePath");
    final buffer = blob.buffer;
    fs.createFile("/app-file/$outputFilename");
    fs.write(
      "/app-file/$outputFilename",
      buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes),
      0,
    );
    await fs.flush();
  }
  return sqlite3.open("/app-file/$outputFilename");
}

Future<dynamic> exportSqliteDb(sql.SqliteDb db) async {
  throw UnimplementedError();
}
