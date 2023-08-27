import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:sqlite3/wasm.dart';

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
