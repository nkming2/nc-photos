import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/use_case/scan_dir_offline.dart';
import 'package:test/test.dart';

import '../test_util.dart' as util;

void main() {
  group("ScanDirOffline", () {
    group("single account", () {
      test("root", _root);
      test("subdir", _subDir);
      test("unsupported file", _unsupportedFile);
    });
    group("multiple account", () {
      test("root", _multiAccountRoot);
    });
  });
}

/// Scan root dir
///
/// Files: admin/test1.jpg, admin/test/test2.jpg
/// Scan: admin
/// Expect: all files
Future<void> _root() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test/test2.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
  });

  // convert to set because ScanDirOffline does not guarantee order
  expect(
    (await ScanDirOffline(c)(
            account, File(path: file_util.unstripPath(account, "."))))
        .toSet(),
    files.toSet(),
  );
}

/// Scan sub dir (admin/test)
///
/// Files: admin/test1.jpg, admin/test/test2.jpg
/// Scan: admin/test
/// Expect: admin/test/test2.jpg
Future<void> _subDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test/test2.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
  });

  expect(
    (await ScanDirOffline(c)(
            account, File(path: file_util.unstripPath(account, "test"))))
        .toSet(),
    {files[1]},
  );
}

/// Scan dir with unsupported file
///
/// Files: admin/test1.jpg, admin/test2.pdf
/// Scan: admin
/// Expect: admin/test1.jpg
Future<void> _unsupportedFile() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addGenericFile("admin/test2.pdf", "application/pdf"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
  });

  // convert to set because ScanDirOffline does not guarantee order
  expect(
    (await ScanDirOffline(c)(
            account, File(path: file_util.unstripPath(account, "."))))
        .toSet(),
    {files[0]},
  );
}

/// Scan root dir with multiple accounts
///
/// Files: admin/test1.jpg, admin/test/test2.jpg, user1/test1.jpg,
/// user1/test/test2.jpg
/// Scan: admin
/// Expect: admin/test1.jpg, admin/test/test2.jpg
/// Scan: user1
/// Expect: user1/test1.jpg, user1/test/test2.jpg
Future<void> _multiAccountRoot() async {
  final account = util.buildAccount();
  final user1Account = util.buildAccount(userId: "user1");
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test/test2.jpg"))
      .build();
  final user1Files = (util.FilesBuilder(initialFileId: files.length)
        ..addJpeg("user1/test1.jpg", ownerId: "user1")
        ..addJpeg("user1/test/test2.jpg", ownerId: "user1"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await c.sqliteDb.insertAccountOf(user1Account);
    await util.insertFiles(c.sqliteDb, user1Account, user1Files);
  });

  expect(
    (await ScanDirOffline(c)(
            account, File(path: file_util.unstripPath(account, "."))))
        .toSet(),
    files.toSet(),
  );
  expect(
    (await ScanDirOffline(c)(
            user1Account, File(path: file_util.unstripPath(user1Account, "."))))
        .toSet(),
    user1Files.toSet(),
  );
}
