import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/remove_album.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as util;

void main() {
  KiwiContainer().registerInstance<EventBus>(MockEventBus());

  group("RemoveAlbum", () {
    test("album", _removeAlbum);
    group("shared album", () {
      test("file", _removeSharedAlbum);
      test("file w/ share in other album", _removeSharedAlbumFileInOtherAlbum);
      test("file resynced by others", _removeSharedAlbumResyncedFile);
    });
  });
}

/// Remove an album
///
/// Expect: album deleted
Future<void> _removeAlbum() async {
  final account = util.buildAccount();
  final album1 = util.AlbumBuilder().build();
  final albumFile1 = album1.albumFile!;
  final album2 = util.AlbumBuilder.ofId(albumId: 1).build();
  final albumFile2 = album2.albumFile!;
  final c = DiContainer(
    albumRepo: MockAlbumMemoryRepo([album1, album2]),
    fileRepo: MockFileMemoryRepo([albumFile1, albumFile2]),
    shareRepo: MockShareRepo(),
    sqliteDb: util.buildTestDb(),
    pref: Pref.scoped(PrefMemoryProvider()),
  );
  addTearDown(() => c.sqliteDb.close());

  await RemoveAlbum(c)(
      account, c.albumMemoryRepo.findAlbumByPath(albumFile1.path));
  expect(c.fileMemoryRepo.files, [albumFile2]);
}

/// Remove a shared album (admin -> user1)
///
/// Expect: album deleted;
/// share (admin -> user1) for the album json deleted;
/// share (admin -> user1) for the files deleted
Future<void> _removeSharedAlbum() async {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1"))
      .build();
  final albumFile = album.albumFile!;
  final c = DiContainer(
    albumRepo: MockAlbumMemoryRepo([album]),
    fileRepo: MockFileMemoryRepo([albumFile, ...files]),
    shareRepo: MockShareMemoryRepo([
      util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      util.buildShare(id: "1", file: files[0], shareWith: "user1"),
    ]),
    sqliteDb: util.buildTestDb(),
    pref: Pref.scoped(PrefMemoryProvider({
      "isLabEnableSharedAlbum": true,
    })),
  );
  addTearDown(() => c.sqliteDb.close());

  await RemoveAlbum(c)(
      account, c.albumMemoryRepo.findAlbumByPath(albumFile.path));
  expect(c.fileMemoryRepo.files, [files[0]]);
  expect(c.shareMemoryRepo.shares, const []);
}

/// Remove a shared album (admin -> user1) where the file is also shared in
/// other album (admin -> user1)
///
/// Expect: album deleted;
/// share (admin -> user1) for the album json deleted;
/// share (admin -> user1) for the file unchanged
Future<void> _removeSharedAlbumFileInOtherAlbum() async {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final albums = [
    (util.AlbumBuilder()
          ..addFileItem(files[0])
          ..addShare("user1"))
        .build(),
    (util.AlbumBuilder.ofId(albumId: 1)
          ..addFileItem(files[0])
          ..addShare("user1"))
        .build(),
  ];
  final albumFiles = albums.map((e) => e.albumFile!).toList();
  final c = DiContainer(
    albumRepo: MockAlbumMemoryRepo(albums),
    fileRepo: MockFileMemoryRepo([...albumFiles, ...files]),
    shareRepo: MockShareMemoryRepo([
      util.buildShare(id: "0", file: albumFiles[0], shareWith: "user1"),
      util.buildShare(id: "1", file: files[0], shareWith: "user1"),
      util.buildShare(id: "2", file: albumFiles[1], shareWith: "user1"),
    ]),
    sqliteDb: util.buildTestDb(),
    pref: Pref.scoped(PrefMemoryProvider({
      "isLabEnableSharedAlbum": true,
    })),
  );
  addTearDown(() => c.sqliteDb.close());

  await RemoveAlbum(c)(
      account, c.albumMemoryRepo.findAlbumByPath(albumFiles[0].path));
  expect(c.fileMemoryRepo.files, [albumFiles[1], files[0]]);
  expect(c.shareMemoryRepo.shares, [
    util.buildShare(id: "1", file: files[0], shareWith: "user1"),
    util.buildShare(id: "2", file: albumFiles[1], shareWith: "user1"),
  ]);
}

/// Remove a shared album (admin -> user1) where the file is resynced by user1
///
/// Expect: album deleted;
/// share (admin -> user1) for the album json deleted;
/// share (admin -> user1) for the file delete
Future<void> _removeSharedAlbumResyncedFile() async {
  final account = util.buildAccount();
  final user1Account = util.buildAccount(userId: "user1");
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final user1Files = [
    files[0].copyWith(path: "remote.php/dav/files/user1/share/test1.jpg"),
  ];
  final album = (util.AlbumBuilder()
        ..addFileItem(user1Files[0])
        ..addShare("user1"))
      .build();
  final albumFile = album.albumFile!;
  final c = DiContainer(
    albumRepo: MockAlbumMemoryRepo([album]),
    fileRepo: MockFileMemoryRepo([albumFile, ...files, ...user1Files]),
    shareRepo: MockShareMemoryRepo([
      util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      util.buildShare(id: "1", file: files[0], shareWith: "user1"),
    ]),
    sqliteDb: util.buildTestDb(),
    pref: Pref.scoped(PrefMemoryProvider({
      "isLabEnableSharedAlbum": true,
    })),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await c.sqliteDb.insertAccountOf(user1Account);
    await util.insertFiles(c.sqliteDb, account, files);

    await util.insertFiles(c.sqliteDb, user1Account, user1Files);
  });

  await RemoveAlbum(c)(
      account, c.albumMemoryRepo.findAlbumByPath(albumFile.path));
  expect(c.fileMemoryRepo.files, [...files, ...user1Files]);
  expect(c.shareMemoryRepo.shares, []);
}
