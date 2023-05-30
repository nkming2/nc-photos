import 'dart:io' as dart;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos_plugin/nc_photos_plugin.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart' as sql;

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
  return sql.applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
}

Future<CommonDatabase> openRawSqliteDbFromAsset(
  String assetRelativePath,
  String outputFilename, {
  bool isReadOnly = false,
}) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = dart.File(path_lib.join(dbFolder.path, outputFilename));
  if (!await file.exists()) {
    // copy file from assets
    final blob = await rootBundle.load("assets/$assetRelativePath");
    final buffer = blob.buffer;
    await file.writeAsBytes(
      buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes),
      flush: true,
    );
  }
  return sqlite3.open(
    file.path,
    mode: isReadOnly ? OpenMode.readOnly : OpenMode.readWriteCreate,
  );
}

Future<dynamic> exportSqliteDb(sql.SqliteDb db) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = dart.File(path_lib.join(dir.path, "export.sqlite"));
  if (await file.exists()) {
    await file.delete();
  }
  await db.customStatement("VACUUM INTO ?", [file.path]);
  return MediaStore.copyFileToDownload(file.path);
}
