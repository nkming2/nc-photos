import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/list_extension.dart';
import 'package:np_common/or_null.dart';
import 'package:test/test.dart';

import '../../test_util.dart' as util;

void main() {
  group("FileSqliteDbDataSource", () {
    test("list", _list);
    test("listSingle", _listSingle);
    group("remove", () {
      test("file", _removeFile);
      test("empty dir", _removeEmptyDir);
      test("dir w/ file", _removeDir);
      test("dir w/ sub dir", _removeDirWithSubDir);
    });
    group("updateProperty", () {
      test("file properties", _updateFileProperty);
      test("update metadata", _updateMetadata);
      test("add metadata", _updateAddMetadata);
      test("delete metadata", _updateDeleteMetadata);
    });
  });
}

/// List a dir
///
/// Files: admin/test1.jpg, admin/test/test2.jpg
/// List: admin
/// Expect: admin/test1.jpg
/// List: admin/test
/// Expect: admin/test/test2.jpg
Future<void> _list() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg")
        ..addDir("admin/test")
        ..addJpeg("admin/test/test2.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(
        c.sqliteDb, account, files[0], files.slice(1, 3));
    await util.insertDirRelation(c.sqliteDb, account, files[2], [files[3]]);
  });

  final src = FileSqliteDbDataSource(c);
  expect(await src.list(account, files[0]), files.slice(0, 3));
  expect(await src.list(account, files[2]), files.slice(2, 4));
}

/// List a single dir
///
/// Expect: throw UnimplementedError
Future<void> _listSingle() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()..addDir("admin")).build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], const []);
  });

  final src = FileSqliteDbDataSource(c);
  expect(() async => await src.listSingle(account, files[0]),
      throwsUnimplementedError);
}

/// Remove a file
///
/// Expect: entry removed from Files table
Future<void> _removeFile() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
  });

  final src = FileSqliteDbDataSource(c);
  await src.remove(account, files[1]);
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {files[0]},
  );
}

/// Remove an empty dir
///
/// Expect: entry removed from DirFiles table
Future<void> _removeEmptyDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addDir("admin/test"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
    await util.insertDirRelation(c.sqliteDb, account, files[1], const []);
  });

  final src = FileSqliteDbDataSource(c);
  await src.remove(account, files[1]);
  // parent dir is not updated, parent dir is only updated when syncing with
  // remote
  expect(
    await util.listSqliteDbDirs(c.sqliteDb),
    {
      files[0]: {files[0]},
    },
  );
}

/// Remove a dir with file
///
/// Expect: file entries under the dir removed from Files table
Future<void> _removeDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addDir("admin/test")
        ..addJpeg("admin/test/test1.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
    await util.insertDirRelation(c.sqliteDb, account, files[1], [files[2]]);
  });

  final src = FileSqliteDbDataSource(c);
  await src.remove(account, files[1]);
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {files[0]},
  );
}

/// Remove a dir with file
///
/// Expect: file entries under the dir removed from Files table
Future<void> _removeDirWithSubDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addDir("admin/test")
        ..addDir("admin/test/test2")
        ..addJpeg("admin/test/test2/test3.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
    await util.insertDirRelation(c.sqliteDb, account, files[1], [files[2]]);
    await util.insertDirRelation(c.sqliteDb, account, files[2], [files[3]]);
  });

  final src = FileSqliteDbDataSource(c);
  await src.remove(account, files[1]);
  expect(
    await util.listSqliteDbDirs(c.sqliteDb),
    {
      files[0]: {files[0]}
    },
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {files[0]},
  );
}

/// Update the properties of a file
///
/// Expect: file's property updated in Files table
Future<void> _updateFileProperty() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
  });

  final src = FileSqliteDbDataSource(c);
  await src.updateProperty(
    account,
    files[1],
    isArchived: const OrNull(true),
    overrideDateTime: OrNull(DateTime.utc(2020, 1, 2, 3, 4, 5)),
  );
  final expectFile = files[1].copyWith(
    isArchived: const OrNull(true),
    overrideDateTime: OrNull(DateTime.utc(2020, 1, 2, 3, 4, 5)),
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {files[0], expectFile},
  );
}

/// Update metadata of a file
///
/// Expect: Metadata updated in Images table
Future<void> _updateMetadata() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  files[1] = files[1].copyWith(
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      imageWidth: 123,
    )),
  );
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
  });

  final src = FileSqliteDbDataSource(c);
  await src.updateProperty(
    account,
    files[1],
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2021, 1, 2, 3, 4, 5),
      imageWidth: 321,
      imageHeight: 123,
    )),
  );
  final expectFile = files[1].copyWith(
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2021, 1, 2, 3, 4, 5),
      imageWidth: 321,
      imageHeight: 123,
    )),
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {files[0], expectFile},
  );
}

/// Add metadata to a file
///
/// Expect: Metadata added to Images table
Future<void> _updateAddMetadata() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
  });

  final src = FileSqliteDbDataSource(c);
  await src.updateProperty(
    account,
    files[1],
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      imageWidth: 123,
    )),
  );
  final expectFile = files[1].copyWith(
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      imageWidth: 123,
    )),
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {files[0], expectFile},
  );
}

/// Delete metadata of a file
///
/// Expect: Metadata deleted from Images table
Future<void> _updateDeleteMetadata() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  files[1] = files[1].copyWith(
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      imageWidth: 123,
    )),
  );
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);
  });

  final src = FileSqliteDbDataSource(c);
  await src.updateProperty(
    account,
    files[1],
    metadata: const OrNull(null),
  );
  final expectFile = files[1].copyWith(
    metadata: const OrNull(null),
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {files[0], expectFile},
  );
}
