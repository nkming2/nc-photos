import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/use_case/find_file.dart';
import 'package:test/test.dart';

import '../test_util.dart' as util;

void main() {
  group("FindFile", () {
    test("file", _findFile);
    test("missing file", _findMissingFile);
  });
}

/// Find a file in app db
///
/// Expect: return the file found
Future<void> _findFile() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test2.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
  });

  expect(await FindFile(c)(account, [1]), [files[1]]);
}

/// Find a file not existing in app db
///
/// Expect: throw StateError
Future<void> _findMissingFile() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()..addJpeg("admin/test1.jpg")).build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
  });

  expect(() => FindFile(c)(account, [1]), throwsStateError);
}
