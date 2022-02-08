import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/use_case/compat/v37.dart';
import 'package:test/test.dart';

import '../../mock_type.dart';
import '../../test_util.dart' as util;

void main() {
  group("CompatV37", () {
    group("isAppDbNeedMigration", () {
      test("w/ meta entry == false", _isAppDbNeedMigrationEntryFalse);
      test("w/ meta entry == true", _isAppDbNeedMigrationEntryTrue);
      test("w/o meta entry", _isAppDbNeedMigrationWithoutEntry);
    });
    group("migrateAppDb", () {
      test("w/o nomedia", _migrateAppDbWithoutNomedia);
      test("w/ nomedia", _migrateAppDb);
      test("w/ nomedia nested dir", _migrateAppDbNestedDir);
      test("w/ nomedia nested no media marker", _migrateAppDbNestedMarker);
      test("w/ nomedia root", _migrateAppDbRoot);
    });
  });
}

/// Check if migration is necessary with isMigrated flag = false
///
/// Expect: true
Future<void> _isAppDbNeedMigrationEntryFalse() async {
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.metaStoreName, idbModeReadWrite);
    final metaStore = transaction.objectStore(AppDb.metaStoreName);
    const entry = AppDbMetaEntryCompatV37(false);
    await metaStore.put(entry.toEntry().toJson());
  });

  expect(await CompatV37.isAppDbNeedMigration(appDb), true);
}

/// Check if migration is necessary with isMigrated flag = true
///
/// Expect: false
Future<void> _isAppDbNeedMigrationEntryTrue() async {
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.metaStoreName, idbModeReadWrite);
    final metaStore = transaction.objectStore(AppDb.metaStoreName);
    const entry = AppDbMetaEntryCompatV37(true);
    await metaStore.put(entry.toEntry().toJson());
  });

  expect(await CompatV37.isAppDbNeedMigration(appDb), false);
}

/// Check if migration is necessary with isMigrated flag missing
///
/// Expect: false
Future<void> _isAppDbNeedMigrationWithoutEntry() async {
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.metaStoreName, idbModeReadWrite);
    final metaStore = transaction.objectStore(AppDb.metaStoreName);
    const entry = AppDbMetaEntryCompatV37(true);
    await metaStore.put(entry.toEntry().toJson());
  });

  expect(await CompatV37.isAppDbNeedMigration(appDb), false);
}

/// Migrate db without nomedia file
///
/// Expect: all files remain
Future<void> _migrateAppDbWithoutNomedia() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg")
        ..addDir("admin/dir1")
        ..addJpeg("admin/dir1/test2.jpg"))
      .build();
  final appDb = MockAppDb();
  await appDb.use((db) async {
    await util.fillAppDb(appDb, account, files);
    await util.fillAppDbDir(appDb, account, files[0], files.slice(1, 3));
    await util.fillAppDbDir(appDb, account, files[2], [files[3]]);
  });
  await CompatV37.migrateAppDb(appDb);

  final fileObjs = await util.listAppDb(
      appDb, AppDb.file2StoreName, (e) => AppDbFile2Entry.fromJson(e).file);
  expect(fileObjs, files);
  final dirEntries = await util.listAppDb(
      appDb, AppDb.dirStoreName, (e) => AppDbDirEntry.fromJson(e));
  expect(dirEntries, [
    AppDbDirEntry.fromFiles(account, files[0], files.slice(1, 3)),
    AppDbDirEntry.fromFiles(account, files[2], [files[3]]),
  ]);
}

/// Migrate db with nomedia file
///
/// nomedia: admin/dir1/.nomedia
/// Expect: files (except .nomedia) under admin/dir1 removed
Future<void> _migrateAppDb() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg")
        ..addDir("admin/dir1")
        ..addGenericFile("admin/dir1/.nomedia", "text/plain")
        ..addJpeg("admin/dir1/test2.jpg"))
      .build();
  final appDb = MockAppDb();
  await appDb.use((db) async {
    await util.fillAppDb(appDb, account, files);
    await util.fillAppDbDir(appDb, account, files[0], files.slice(1, 3));
    await util.fillAppDbDir(appDb, account, files[2], files.slice(3, 5));
  });
  await CompatV37.migrateAppDb(appDb);

  final fileObjs = await util.listAppDb(
      appDb, AppDb.file2StoreName, (e) => AppDbFile2Entry.fromJson(e).file);
  expect(fileObjs, files.slice(0, 4));
  final dirEntries = await util.listAppDb(
      appDb, AppDb.dirStoreName, (e) => AppDbDirEntry.fromJson(e));
  expect(dirEntries, [
    AppDbDirEntry.fromFiles(account, files[0], files.slice(1, 3)),
    AppDbDirEntry.fromFiles(account, files[2], [files[3]]),
  ]);
}

/// Migrate db with nomedia file
///
/// nomedia: admin/dir1/.nomedia
/// Expect: files (except .nomedia) under admin/dir1 removed
Future<void> _migrateAppDbNestedDir() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg")
        ..addDir("admin/dir1")
        ..addGenericFile("admin/dir1/.nomedia", "text/plain")
        ..addJpeg("admin/dir1/test2.jpg")
        ..addDir("admin/dir1/dir1-1")
        ..addJpeg("admin/dir1/dir1-1/test3.jpg"))
      .build();
  final appDb = MockAppDb();
  await appDb.use((db) async {
    await util.fillAppDb(appDb, account, files);
    await util.fillAppDbDir(appDb, account, files[0], files.slice(1, 3));
    await util.fillAppDbDir(appDb, account, files[2], files.slice(3, 6));
    await util.fillAppDbDir(appDb, account, files[5], [files[6]]);
  });
  await CompatV37.migrateAppDb(appDb);

  final fileObjs = await util.listAppDb(
      appDb, AppDb.file2StoreName, (e) => AppDbFile2Entry.fromJson(e).file);
  expect(fileObjs, files.slice(0, 4));
  final dirEntries = await util.listAppDb(
      appDb, AppDb.dirStoreName, (e) => AppDbDirEntry.fromJson(e));
  expect(dirEntries, [
    AppDbDirEntry.fromFiles(account, files[0], files.slice(1, 3)),
    AppDbDirEntry.fromFiles(account, files[2], [files[3]]),
  ]);
}

/// Migrate db with nomedia file
///
/// nomedia: admin/dir1/.nomedia, admin/dir1/dir1-1/.nomedia
/// Expect: files (except admin/dir1/.nomedia) under admin/dir1 removed
Future<void> _migrateAppDbNestedMarker() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg")
        ..addDir("admin/dir1")
        ..addGenericFile("admin/dir1/.nomedia", "text/plain")
        ..addJpeg("admin/dir1/test2.jpg")
        ..addDir("admin/dir1/dir1-1")
        ..addGenericFile("admin/dir1/dir1-1/.nomedia", "text/plain")
        ..addJpeg("admin/dir1/dir1-1/test3.jpg"))
      .build();
  final appDb = MockAppDb();
  await appDb.use((db) async {
    await util.fillAppDb(appDb, account, files);
    await util.fillAppDbDir(appDb, account, files[0], files.slice(1, 3));
    await util.fillAppDbDir(appDb, account, files[2], files.slice(3, 6));
    await util.fillAppDbDir(appDb, account, files[5], files.slice(6, 8));
  });
  await CompatV37.migrateAppDb(appDb);

  final fileObjs = await util.listAppDb(
      appDb, AppDb.file2StoreName, (e) => AppDbFile2Entry.fromJson(e).file);
  expect(fileObjs, files.slice(0, 4));
  final dirEntries = await util.listAppDb(
      appDb, AppDb.dirStoreName, (e) => AppDbDirEntry.fromJson(e));
  expect(dirEntries, [
    AppDbDirEntry.fromFiles(account, files[0], files.slice(1, 3)),
    AppDbDirEntry.fromFiles(account, files[2], [files[3]]),
  ]);
}

/// Migrate db with nomedia file
///
/// nomedia: admin/.nomedia
/// Expect: files (except .nomedia) under admin removed
Future<void> _migrateAppDbRoot() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addGenericFile("admin/.nomedia", "text/plain")
        ..addJpeg("admin/test1.jpg")
        ..addDir("admin/dir1")
        ..addJpeg("admin/dir1/test2.jpg"))
      .build();
  final appDb = MockAppDb();
  await appDb.use((db) async {
    await util.fillAppDb(appDb, account, files);
    await util.fillAppDbDir(appDb, account, files[0], files.slice(1, 4));
    await util.fillAppDbDir(appDb, account, files[3], [files[4]]);
  });
  await CompatV37.migrateAppDb(appDb);

  final objs = await util.listAppDb(
      appDb, AppDb.file2StoreName, (e) => AppDbFile2Entry.fromJson(e).file);
  expect(objs, files.slice(0, 2));
  final dirEntries = await util.listAppDb(
      appDb, AppDb.dirStoreName, (e) => AppDbDirEntry.fromJson(e));
  expect(dirEntries, [
    AppDbDirEntry.fromFiles(account, files[0], [files[1]]),
  ]);
}
