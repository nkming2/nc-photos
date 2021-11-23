import 'package:event_bus/event_bus.dart';
import 'package:idb_shim/idb.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/add_to_album.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as test_util;

void main() {
  KiwiContainer().registerInstance<EventBus>(MockEventBus());

  group("AddToAlbum", () {
    test("file", _addFile);
    group("shared album (owned)", () {
      test("file", _addFileToSharedAlbumOwned);
      test("file owned by user", _addFileOwnedByUserToSharedAlbumOwned);
    });
    group("shared album (not owned)", () {
      test("file", _addFileToMultiuserSharedAlbumNotOwned);
    });
  });
}

/// Add a [File] to an [Album]
///
/// Expect: file added to album
Future<void> _addFile() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final file = (test_util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg"))
      .build()[0];
  final album = test_util.AlbumBuilder().build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file));
  });
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareRepo();

  await AddToAlbum(albumRepo, shareRepo, appDb, pref)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    [
      AlbumFileItem(
        addedBy: "admin".toCi(),
        addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
        file: file,
      ),
    ],
  );
  expect(
    albumRepo.albums
        .map((e) => e.copyWith(
              // we need to set a known value to lastUpdated
              lastUpdated: OrNull(DateTime.utc(2020, 1, 2, 3, 4, 5)),
            ))
        .toList(),
    [
      Album(
        lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
        name: "test",
        provider: AlbumStaticProvider(
          items: [
            AlbumFileItem(
              addedBy: "admin".toCi(),
              addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
              file: file,
            ),
          ],
          latestItemTime: DateTime.utc(2020, 1, 2, 3, 4, 5),
        ),
        coverProvider: AlbumAutoCoverProvider(
          coverFile: file,
        ),
        sortProvider: const AlbumNullSortProvider(),
        albumFile: albumFile,
      ),
    ],
  );
}

/// Add a file to a shared album (admin -> user1)
///
/// Expect: a new share (admin -> user1) is created for the file
Future<void> _addFileToSharedAlbumOwned() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final file = (test_util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg"))
      .build()[0];
  final album = (test_util.AlbumBuilder()..addShare("user1")).build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file));
  });
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
  ]);

  await AddToAlbum(albumRepo, shareRepo, appDb, pref)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    [
      AlbumFileItem(
        addedBy: "admin".toCi(),
        addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
        file: file,
      ),
    ],
  );

  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      test_util.buildShare(id: "1", file: file, shareWith: "user1"),
    ],
  );
}

/// Add a file owned by user (user1) to a shared album (admin -> user1)
///
/// Expect: no shares created
Future<void> _addFileOwnedByUserToSharedAlbumOwned() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final file = (test_util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg", ownerId: "user1"))
      .build()[0];
  final album = (test_util.AlbumBuilder()..addShare("user1")).build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file));
  });
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
  ]);

  await AddToAlbum(albumRepo, shareRepo, appDb, pref)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    [
      AlbumFileItem(
        addedBy: "admin".toCi(),
        addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
        file: file,
      ),
    ],
  );

  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    ],
  );
}

/// Add a file to a shared album (user1 -> admin, user2)
///
/// Expect: a new share (admin -> user1, user2) is created for the file
Future<void> _addFileToMultiuserSharedAlbumNotOwned() async {
  // doesn't work right now, skipped
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final file = (test_util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg"))
      .build()[0];
  final album = (test_util.AlbumBuilder(ownerId: "user1")
        ..addShare("admin")
        ..addShare("user2"))
      .build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file));
  });
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(
        id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
    test_util.buildShare(
        id: "1", uidOwner: "user1", file: albumFile, shareWith: "user2"),
  ]);

  await AddToAlbum(albumRepo, shareRepo, appDb, pref)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    [
      AlbumFileItem(
        addedBy: "admin".toCi(),
        addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
        file: file,
      ),
    ],
  );
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(
          id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
      test_util.buildShare(
          id: "1", uidOwner: "user1", file: albumFile, shareWith: "user2"),
      // the order for these two shares are actually NOT guaranteed
      test_util.buildShare(id: "2", file: file, shareWith: "user2"),
      test_util.buildShare(id: "3", file: file, shareWith: "user1"),
    ],
  );
}
