import 'package:event_bus/event_bus.dart';
import 'package:idb_shim/idb.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/app_db.dart';
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
    });
  });
}

/// Remove an album
///
/// Expect: album deleted
Future<void> _removeAlbum() async {
  final account = util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final album1 = util.AlbumBuilder().build();
  final albumFile1 = album1.albumFile!;
  final album2 = util.AlbumBuilder.ofId(albumId: 1).build();
  final albumFile2 = album2.albumFile!;
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, albumFile1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, albumFile1));
    await store.put(AppDbFileDbEntry.fromFile(account, albumFile2).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, albumFile2));
  });
  final fileRepo = MockFileMemoryRepo([albumFile1, albumFile2]);
  final albumRepo = MockAlbumMemoryRepo([album1, album2]);
  final shareRepo = MockShareRepo();

  await RemoveAlbum(fileRepo, albumRepo, shareRepo, pref)(
      account, albumRepo.findAlbumByPath(albumFile1.path));
  expect(fileRepo.files, [albumFile2]);
}

/// Remove a shared album (admin -> user1)
///
/// Expect: album deleted;
/// share (admin -> user1) for the album json deleted;
/// share (admin -> user1) for the files deleted
Future<void> _removeSharedAlbum() async {
  final account = util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1"))
      .build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, albumFile).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, albumFile));
    await store.put(AppDbFileDbEntry.fromFile(account, files[0]).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, files[0]));
  });
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    util.buildShare(id: "1", file: files[0], shareWith: "user1"),
  ]);

  await RemoveAlbum(fileRepo, albumRepo, shareRepo, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path));
  expect(fileRepo.files, [files[0]]);
  expect(shareRepo.shares, const []);
}

/// Remove a shared album (admin -> user1) where the file is
/// also shared in other album (admin -> user1)
///
/// Expect: album deleted;
/// share (admin -> user1) for the album json deleted;
/// share (admin -> user1) for the file unchanged
Future<void> _removeSharedAlbumFileInOtherAlbum() async {
  final account = util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
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
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, albumFiles[0]).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, albumFiles[0]));
    await store.put(AppDbFileDbEntry.fromFile(account, albumFiles[1]).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, albumFiles[1]));
    await store.put(AppDbFileDbEntry.fromFile(account, files[0]).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, files[0]));
  });
  final fileRepo = MockFileMemoryRepo([...albumFiles, ...files]);
  final albumRepo = MockAlbumMemoryRepo(albums);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFiles[0], shareWith: "user1"),
    util.buildShare(id: "1", file: files[0], shareWith: "user1"),
    util.buildShare(id: "2", file: albumFiles[1], shareWith: "user1"),
  ]);

  await RemoveAlbum(fileRepo, albumRepo, shareRepo, pref)(
      account, albumRepo.findAlbumByPath(albumFiles[0].path));
  expect(fileRepo.files, [albumFiles[1], files[0]]);
  expect(shareRepo.shares, [
    util.buildShare(id: "1", file: files[0], shareWith: "user1"),
    util.buildShare(id: "2", file: albumFiles[1], shareWith: "user1"),
  ]);
}
