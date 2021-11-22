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
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/remove_from_album.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as test_util;

void main() {
  KiwiContainer().registerInstance<EventBus>(MockEventBus());

  group("RemoveFromAlbum", () {
    test("last file", _removeLastFile);
    test("1 of N files", _remove1OfNFiles);
    test("latest of N files", _removeLatestOfNFiles);
    test("manual cover file", _removeManualCoverFile);
    group("shared album (owned)", () {
      test("file", _removeFromSharedAlbumOwned);
      test("file w/ shares managed by others",
          _removeFromSharedAlbumOwnedWithOtherShare);
    });
    group("shared album (not owned)", () {
      test("file", _removeFromSharedAlbumNotOwned);
      test("file w/ shares managed by owner",
          _removeFromSharedAlbumNotOwnedWithOwnerShare);
      test("file w/ extra share", _removeFromSharedAlbumLeaveExtraShare);
    });
  });
}

/// Remove the last file from an album
///
/// Expect: album emptied, cover unset
Future<void> _removeLastFile() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1],
        latestItemTime: file1.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
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
        provider: AlbumStaticProvider(items: []),
        coverProvider: AlbumAutoCoverProvider(),
        sortProvider: const AlbumNullSortProvider(),
        albumFile: albumFile,
      ),
    ],
  );
}

/// Remove a file from an album
///
/// Expect: file removed from album
Future<void> _remove1OfNFiles() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final file2 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test2.jpg",
    fileId: 2,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 6),
  );
  final fileItem2 = AlbumFileItem(
    file: file2,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 6),
  );
  final file3 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test3.jpg",
    fileId: 3,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 7),
  );
  final fileItem3 = AlbumFileItem(
    file: file3,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 7),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
    await store.put(AppDbFileDbEntry.fromFile(account, file2).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file2));
    await store.put(AppDbFileDbEntry.fromFile(account, file3).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file3));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1, fileItem2, fileItem3],
        latestItemTime: file3.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file3),
      sortProvider: const AlbumNullSortProvider(),
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, file1, file2, file3]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    albumRepo.albums
        .map((e) => e.copyWith(
              // we need to set a known value to lastUpdated
              lastUpdated: OrNull(DateTime.utc(2020, 1, 2, 3, 4, 5).toUtc()),
            ))
        .toList(),
    [
      Album(
        lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
        name: "test",
        provider: AlbumStaticProvider(
          items: [fileItem2, fileItem3],
          latestItemTime: file3.lastModified,
        ),
        coverProvider: AlbumAutoCoverProvider(coverFile: file3),
        sortProvider: const AlbumNullSortProvider(),
        albumFile: albumFile,
      ),
    ],
  );
}

/// Remove the latest file from an album
///
/// Expect: file removed from album, auto cover and time updated
Future<void> _removeLatestOfNFiles() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 8),
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 8),
  );
  final file2 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test2.jpg",
    fileId: 2,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 6),
  );
  final fileItem2 = AlbumFileItem(
    file: file2,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 6),
  );
  final file3 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test3.jpg",
    fileId: 3,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 7),
  );
  final fileItem3 = AlbumFileItem(
    file: file3,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 7),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
    await store.put(AppDbFileDbEntry.fromFile(account, file2).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file2));
    await store.put(AppDbFileDbEntry.fromFile(account, file3).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file3));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1, fileItem2, fileItem3],
        latestItemTime: file1.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, file1, file2, file3]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    albumRepo.albums
        .map((e) => e.copyWith(
              // we need to set a known value to lastUpdated
              lastUpdated: OrNull(DateTime.utc(2020, 1, 2, 3, 4, 5).toUtc()),
            ))
        .toList(),
    [
      Album(
        lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
        name: "test",
        provider: AlbumStaticProvider(
          items: [fileItem2, fileItem3],
          latestItemTime: file3.lastModified,
        ),
        coverProvider: AlbumAutoCoverProvider(coverFile: file3),
        sortProvider: const AlbumNullSortProvider(),
        albumFile: albumFile,
      ),
    ],
  );
}

/// Remove the manual cover file from album
///
/// Expect: file removed from album, cover reverted to auto cover
Future<void> _removeManualCoverFile() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final file2 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test2.jpg",
    fileId: 2,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 6),
  );
  final fileItem2 = AlbumFileItem(
    file: file2,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 6),
  );
  final file3 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test3.jpg",
    fileId: 3,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 7),
  );
  final fileItem3 = AlbumFileItem(
    file: file3,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 7),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
    await store.put(AppDbFileDbEntry.fromFile(account, file2).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file2));
    await store.put(AppDbFileDbEntry.fromFile(account, file3).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file3));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1, fileItem2, fileItem3],
        latestItemTime: file3.lastModified,
      ),
      coverProvider: AlbumManualCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, file1, file2, file3]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
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
          items: [fileItem2, fileItem3],
          latestItemTime: file3.lastModified,
        ),
        coverProvider: AlbumAutoCoverProvider(coverFile: file3),
        sortProvider: const AlbumNullSortProvider(),
        albumFile: albumFile,
      ),
    ],
  );
}

/// Remove a file from a shared album (admin -> user1)
///
/// Expect: share (admin -> user1) for the file deleted
Future<void> _removeFromSharedAlbumOwned() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
    ownerId: "admin",
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1],
        latestItemTime: file1.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      shares: [AlbumShare(userId: "user1".toCi())],
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    test_util.buildShare(id: "1", file: file1, shareWith: "user1"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [test_util.buildShare(id: "0", file: albumFile, shareWith: "user1")],
  );
}

/// Remove a file (user1 -> admin, user2) from a shared album
/// (admin -> user1, user2)
///
/// Expect: shares (user1 -> admin, user2) for the file created by others
/// unchanged
Future<void> _removeFromSharedAlbumOwnedWithOtherShare() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
    ownerId: "admin",
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1],
        latestItemTime: file1.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      shares: [AlbumShare(userId: "user1".toCi())],
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    test_util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
    test_util.buildShare(
        id: "2", uidOwner: "user1", file: file1, shareWith: "admin"),
    test_util.buildShare(
        id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      test_util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
      test_util.buildShare(
          id: "2", uidOwner: "user1", file: file1, shareWith: "admin"),
      test_util.buildShare(
          id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
    ],
  );
}

/// Remove a file from a shared album (user1 -> admin, user2)
///
/// Expect: shares (admin -> user1, user2) for the file deleted
Future<void> _removeFromSharedAlbumNotOwned() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
    ownerId: "user1",
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1],
        latestItemTime: file1.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      shares: [
        AlbumShare(userId: "admin".toCi()),
        AlbumShare(userId: "user2".toCi()),
      ],
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(
        id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
    test_util.buildShare(
        id: "1", uidOwner: "user1", file: albumFile, shareWith: "user2"),
    test_util.buildShare(id: "2", file: file1, shareWith: "user1"),
    test_util.buildShare(id: "3", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(
          id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
      test_util.buildShare(
          id: "1", uidOwner: "user1", file: albumFile, shareWith: "user2"),
    ],
  );
}

/// Remove a file (admin -> user1 | user1 -> user2) from a shared album
/// (user1 -> admin, user2)
///
/// Expect: shares (admin -> user1) for the file created by us deleted;
/// shares (user1 -> user2) for the file created by others unchanged
Future<void> _removeFromSharedAlbumNotOwnedWithOwnerShare() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
    ownerId: "user1",
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1],
        latestItemTime: file1.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      shares: [
        AlbumShare(userId: "admin".toCi()),
        AlbumShare(userId: "user2".toCi()),
      ],
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(
        id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
    test_util.buildShare(id: "1", file: file1, shareWith: "user1"),
    test_util.buildShare(
        id: "2", uidOwner: "user1", file: albumFile, shareWith: "user2"),
    test_util.buildShare(
        id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(
          id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
      test_util.buildShare(
          id: "2", uidOwner: "user1", file: albumFile, shareWith: "user2"),
      test_util.buildShare(
          id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
    ],
  );
}

/// Remove a file from a shared album (admin -> user1) with extra unmanaged
/// share (admin -> user2)
///
/// Expect: share (admin -> user1) for the file deleted;
/// extra share (admin -> user2) unchanged
Future<void> _removeFromSharedAlbumLeaveExtraShare() async {
  final account = test_util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider({
    "isLabEnableSharedAlbum": true,
  }));
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
    ownerId: "user1",
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
  });
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1],
        latestItemTime: file1.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file1),
      sortProvider: const AlbumNullSortProvider(),
      shares: [AlbumShare(userId: "admin".toCi())],
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(
        id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
    test_util.buildShare(id: "1", file: file1, shareWith: "user1"),
    test_util.buildShare(id: "2", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb, pref)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(
          id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
      test_util.buildShare(id: "2", file: file1, shareWith: "user2"),
    ],
  );
}
