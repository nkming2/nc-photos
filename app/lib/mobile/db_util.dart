import 'dart:io' as dart;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart' as sqlite3;

Future<Map<String, dynamic>> getSqliteConnectionArgs() async {
  // put the database file, called db.sqlite here, into the documents folder
  // for your app.
  final dbFolder = await getApplicationDocumentsDirectory();
  return {
    "path": path_lib.join(dbFolder.path, "db.sqlite"),
  };
}

QueryExecutor openSqliteConnectionWithArgs(Map<String, dynamic> args) {
  final file = dart.File(args["path"]);
  return NativeDatabase(
    file,
    // logStatements: true,
  );
}

QueryExecutor openSqliteConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    final args = await getSqliteConnectionArgs();
    return openSqliteConnectionWithArgs(args);
  });
}

Future<void> applyWorkaroundToOpenSqlite3OnOldAndroidVersions() {
  return sqlite3.applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
}
