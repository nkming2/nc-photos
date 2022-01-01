import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:test/test.dart';

import '../../mock_type.dart';
import '../../test_util.dart' as util;

void main() {
  group("FileAppDbDataSource", () {
    test("list", _list);
    test("listSingle", _listSingle);
    group("remove", () {
      test("file", _removeFile);
      test("empty dir", _removeEmptyDir);
      test("dir w/ file", _removeDir);
      test("dir w/ sub dir", _removeDirWithSubDir);
    });
    test("updateProperty", _updateProperty);
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
  final appDb = await MockAppDb().applyFuture((obj) async {
    await util.fillAppDb(obj, account, files);
    await util.fillAppDbDir(obj, account, files[0], files.slice(1, 3));
    await util.fillAppDbDir(obj, account, files[2], [files[3]]);
  });
  final src = FileAppDbDataSource(appDb);
  expect(await src.list(account, files[0]), files.slice(0, 3));
  expect(await src.list(account, files[2]), files.slice(2, 4));
}

/// List a single dir
///
/// Expect: throw UnimplementedError
Future<void> _listSingle() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()..addDir("admin")).build();
  final appDb = await MockAppDb().applyFuture((obj) async {
    await util.fillAppDbDir(obj, account, files[0], []);
  });
  final src = FileAppDbDataSource(appDb);
  expect(() async => await src.listSingle(account, files[0]),
      throwsUnimplementedError);
}

/// Remove a file
///
/// Expect: entry removed from file2Store
Future<void> _removeFile() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final appDb = await MockAppDb().applyFuture((obj) async {
    await util.fillAppDb(obj, account, files);
    await util.fillAppDbDir(obj, account, files[0], [files[1]]);
  });
  final src = FileAppDbDataSource(appDb);
  await src.remove(account, files[1]);
  expect(
    (await util.listAppDb(
            appDb, AppDb.file2StoreName, AppDbFile2Entry.fromJson))
        .map((e) => e.file)
        .toList(),
    [files[0]],
  );
}

/// Remove an empty dir
///
/// Expect: dir entry removed from dirStore;
/// no changes to parent dir entry
Future<void> _removeEmptyDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addDir("admin/test"))
      .build();
  final appDb = await MockAppDb().applyFuture((obj) async {
    await util.fillAppDb(obj, account, files);
    await util.fillAppDbDir(obj, account, files[0], [files[1]]);
    await util.fillAppDbDir(obj, account, files[1], []);
  });
  final src = FileAppDbDataSource(appDb);
  await src.remove(account, files[1]);
  // parent dir is not updated, parent dir is only updated when syncing with
  // remote
  expect(
    await util.listAppDb(appDb, AppDb.dirStoreName, AppDbDirEntry.fromJson),
    [
      AppDbDirEntry.fromFiles(account, files[0], [files[1]]),
    ],
  );
}

/// Remove a dir with file
///
/// Expect: file entries under the dir removed from file2Store
Future<void> _removeDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addDir("admin/test")
        ..addJpeg("admin/test/test1.jpg"))
      .build();
  final appDb = await MockAppDb().applyFuture((obj) async {
    await util.fillAppDb(obj, account, files);
    await util.fillAppDbDir(obj, account, files[0], [files[1]]);
    await util.fillAppDbDir(obj, account, files[1], [files[2]]);
  });
  final src = FileAppDbDataSource(appDb);
  await src.remove(account, files[1]);
  expect(
    (await util.listAppDb(
            appDb, AppDb.file2StoreName, AppDbFile2Entry.fromJson))
        .map((e) => e.file)
        .toList(),
    [files[0]],
  );
}

/// Remove a dir with file
///
/// Expect: file entries under the dir removed from file2Store
Future<void> _removeDirWithSubDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addDir("admin/test")
        ..addDir("admin/test/test2")
        ..addJpeg("admin/test/test2/test3.jpg"))
      .build();
  final appDb = await MockAppDb().applyFuture((obj) async {
    await util.fillAppDb(obj, account, files);
    await util.fillAppDbDir(obj, account, files[0], [files[1]]);
    await util.fillAppDbDir(obj, account, files[1], [files[2]]);
    await util.fillAppDbDir(obj, account, files[2], [files[3]]);
  });
  final src = FileAppDbDataSource(appDb);
  await src.remove(account, files[1]);
  expect(
    await util.listAppDb(appDb, AppDb.dirStoreName, AppDbDirEntry.fromJson),
    [
      AppDbDirEntry.fromFiles(account, files[0], [files[1]]),
    ],
  );
  expect(
    (await util.listAppDb(
            appDb, AppDb.file2StoreName, AppDbFile2Entry.fromJson))
        .map((e) => e.file)
        .toList(),
    [files[0]],
  );
}

/// Update the properties of a file
///
/// Expect: file's property updated in file2Store;
/// file's property updated in dirStore
Future<void> _updateProperty() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final appDb = await MockAppDb().applyFuture((obj) async {
    await util.fillAppDb(obj, account, files);
    await util.fillAppDbDir(obj, account, files[0], [files[1]]);
  });
  final src = FileAppDbDataSource(appDb);
  await src.updateProperty(
    account,
    files[1],
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678),
      imageWidth: 123,
    )),
    isArchived: OrNull(true),
    overrideDateTime: OrNull(DateTime.utc(2020, 1, 2, 3, 4, 5, 678)),
  );
  final expectFile = files[1].copyWith(
    metadata: OrNull(Metadata(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678),
      imageWidth: 123,
    )),
    isArchived: OrNull(true),
    overrideDateTime: OrNull(DateTime.utc(2020, 1, 2, 3, 4, 5, 678)),
  );
  expect(
    await util.listAppDb(appDb, AppDb.dirStoreName, AppDbDirEntry.fromJson),
    [
      AppDbDirEntry.fromFiles(account, files[0], [expectFile]),
    ],
  );
  expect(
    (await util.listAppDb(
            appDb, AppDb.file2StoreName, AppDbFile2Entry.fromJson))
        .map((e) => e.file)
        .toList(),
    [files[0], expectFile],
  );
}
