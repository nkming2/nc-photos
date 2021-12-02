import 'package:event_bus/event_bus.dart';
import 'package:idb_shim/idb.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/remove_from_album.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as util;

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
      test("file w/ extra share", _removeFromSharedAlbumOwnedLeaveExtraShare);
      test("file w/ share in other album",
          _removeFromSharedAlbumOwnedFileInOtherAlbum);
    });
    group("shared album (not owned)", () {
      test("file", _removeFromSharedAlbumNotOwned);
      test("file w/ shares managed by owner",
          _removeFromSharedAlbumNotOwnedWithOwnerShare);
    });
  });
}

/// Remove the last file from an album
///
/// Expect: album emptied, cover unset
Future<void> _removeLastFile() async {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()..addFileItem(files[0])).build();
  final file1 = files[0];
  final fileItem1 = util.AlbumBuilder.fileItemsOf(album)[0];
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
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
  final account = util.buildAccount();
  final files = (util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test2.jpg")
        ..addJpeg("admin/test3.jpg"))
      .build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addFileItem(files[1])
        ..addFileItem(files[2]))
      .build();
  final fileItems = util.AlbumBuilder.fileItemsOf(album);
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItems[0]]);
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
          items: [fileItems[1], fileItems[2]],
          latestItemTime: files[2].lastModified,
        ),
        coverProvider: AlbumAutoCoverProvider(coverFile: files[2]),
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
  final account = util.buildAccount();
  final files = (util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg",
            lastModified: DateTime.utc(2020, 1, 2, 3, 4, 8))
        ..addJpeg("admin/test2.jpg",
            lastModified: DateTime.utc(2020, 1, 2, 3, 4, 7))
        ..addJpeg("admin/test3.jpg",
            lastModified: DateTime.utc(2020, 1, 2, 3, 4, 6)))
      .build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addFileItem(files[1])
        ..addFileItem(files[2]))
      .build();
  final fileItems = util.AlbumBuilder.fileItemsOf(album);
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItems[0]]);
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
          items: [fileItems[1], fileItems[2]],
          latestItemTime: files[1].lastModified,
        ),
        coverProvider: AlbumAutoCoverProvider(coverFile: files[1]),
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
  final account = util.buildAccount();
  final files = (util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test2.jpg")
        ..addJpeg("admin/test3.jpg"))
      .build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0], isCover: true)
        ..addFileItem(files[1])
        ..addFileItem(files[2]))
      .build();
  final fileItems = util.AlbumBuilder.fileItemsOf(album);
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareRepo();
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItems[0]]);
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
          items: [fileItems[1], fileItems[2]],
          latestItemTime: files[2].lastModified,
        ),
        coverProvider: AlbumAutoCoverProvider(coverFile: files[2]),
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
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1"))
      .build();
  final file1 = files[0];
  final fileItem1 = util.AlbumBuilder.fileItemsOf(album)[0];
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    util.buildShare(id: "1", file: file1, shareWith: "user1"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [util.buildShare(id: "0", file: albumFile, shareWith: "user1")],
  );
}

/// Remove a file (user1 -> admin, user2) from a shared album
/// (admin -> user1, user2)
///
/// Expect: shares (user1 -> admin, user2) for the file created by others
/// unchanged
Future<void> _removeFromSharedAlbumOwnedWithOtherShare() async {
  final account = util.buildAccount();
  final user1Account = util.buildAccount(username: "user1");
  final files = (util.FilesBuilder(initialFileId: 1)
        ..addJpeg("user1/test1.jpg", ownerId: "user1"))
      .build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0], addedBy: "user1")
        ..addShare("user1")
        ..addShare("user2"))
      .build();
  final file1 = files[0];
  final fileItem1 = util.AlbumBuilder.fileItemsOf(album)[0];
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, user1Account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
    util.buildShare(
        id: "2", uidOwner: "user1", file: file1, shareWith: "admin"),
    util.buildShare(
        id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
      util.buildShare(
          id: "2", uidOwner: "user1", file: file1, shareWith: "admin"),
      util.buildShare(
          id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
    ],
  );
}

/// Remove a file from a shared album (admin -> user1) with extra unmanaged
/// share (admin -> user2)
///
/// Expect: share (admin -> user1) for the file deleted;
/// extra share (admin -> user2) unchanged
Future<void> _removeFromSharedAlbumOwnedLeaveExtraShare() async {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1"))
      .build();
  final file1 = files[0];
  final fileItem1 = util.AlbumBuilder.fileItemsOf(album)[0];
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    util.buildShare(id: "1", file: file1, shareWith: "user1"),
    util.buildShare(id: "2", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      util.buildShare(id: "2", file: file1, shareWith: "user2"),
    ],
  );
}

/// Remove a file from a shared album (admin -> user1, user2) where the file is
/// also shared in other album (admin -> user1)
///
/// Expect: share (admin -> user2) for the file deleted;
/// share (admin -> user1) for the file unchanged
Future<void> _removeFromSharedAlbumOwnedFileInOtherAlbum() async {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 2)..addJpeg("admin/test1.jpg")).build();
  final album1 = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1")
        ..addShare("user2"))
      .build();
  final album2 = (util.AlbumBuilder.ofId(albumId: 1)
        ..addFileItem(files[0])
        ..addShare("user1"))
      .build();
  final album1fileItems = util.AlbumBuilder.fileItemsOf(album1);
  final album1File = album1.albumFile!;
  final album2File = album2.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album1, album2]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: album1File, shareWith: "user1"),
    util.buildShare(id: "1", file: files[0], shareWith: "user1"),
    util.buildShare(id: "2", file: files[0], shareWith: "user2"),
    util.buildShare(id: "3", file: album2File, shareWith: "user1"),
  ]);
  final fileRepo = MockFileMemoryRepo([album1File, album2File, ...files]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(account,
      albumRepo.findAlbumByPath(album1File.path), [album1fileItems[0]]);
  expect(
    shareRepo.shares,
    [
      util.buildShare(id: "0", file: album1File, shareWith: "user1"),
      util.buildShare(id: "1", file: files[0], shareWith: "user1"),
      util.buildShare(id: "3", file: album2File, shareWith: "user1"),
    ],
  );
}

/// Remove a file from a shared album (user1 -> admin, user2)
///
/// Expect: shares (admin -> user1, user2) for the file deleted
Future<void> _removeFromSharedAlbumNotOwned() async {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder(ownerId: "user1")
        ..addFileItem(files[0])
        ..addShare("admin")
        ..addShare("user2"))
      .build();
  final file1 = files[0];
  final fileItem1 = util.AlbumBuilder.fileItemsOf(album)[0];
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(
        id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
    util.buildShare(
        id: "1", uidOwner: "user1", file: albumFile, shareWith: "user2"),
    util.buildShare(id: "2", file: file1, shareWith: "user1"),
    util.buildShare(id: "3", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      util.buildShare(
          id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
      util.buildShare(
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
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder(ownerId: "user1")
        ..addFileItem(files[0])
        ..addShare("admin")
        ..addShare("user2"))
      .build();
  final file1 = files[0];
  final fileItem1 = util.AlbumBuilder.fileItemsOf(album)[0];
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await appDb.use((db) async {
    final transaction = db.transaction(AppDb.fileDbStoreName, idbModeReadWrite);
    final store = transaction.objectStore(AppDb.fileDbStoreName);
    await store.put(AppDbFileDbEntry.fromFile(account, file1).toJson(),
        AppDbFileDbEntry.toPrimaryKey(account, file1));
  });
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(
        id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
    util.buildShare(id: "1", file: file1, shareWith: "user1"),
    util.buildShare(
        id: "2", uidOwner: "user1", file: albumFile, shareWith: "user2"),
    util.buildShare(
        id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);

  await RemoveFromAlbum(albumRepo, shareRepo, fileRepo, appDb)(
      account, albumRepo.findAlbumByPath(albumFile.path), [fileItem1]);
  expect(
    shareRepo.shares,
    [
      util.buildShare(
          id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
      util.buildShare(
          id: "2", uidOwner: "user1", file: albumFile, shareWith: "user2"),
      util.buildShare(
          id: "3", uidOwner: "user1", file: file1, shareWith: "user2"),
    ],
  );
}
