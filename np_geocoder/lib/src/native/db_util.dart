import 'dart:io' as dart;

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

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
