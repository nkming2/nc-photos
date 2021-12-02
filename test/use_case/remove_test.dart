import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as util;

void main() {
  KiwiContainer().registerInstance<EventBus>(MockEventBus());

  group("Remove", () {
    test("file", _removeFile);
    test("file no clean up", _removeFileNoCleanUp);
    group("album", () {
      test("file", _removeAlbumFile);
      test("file no clean up", _removeAlbumFileNoCleanUp);
    });
    group("shared album", () {
      test("file", _removeSharedAlbumFile);
      test("shared file", _removeSharedAlbumSharedFile);
      test("file resynced by others", _removeSharedAlbumResyncedFile);
    });
  });
}

/// Remove a file
///
/// Expect: file deleted
Future<void> _removeFile() async {
  final account = util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test2.jpg"))
      .build();
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final fileRepo = MockFileMemoryRepo(files);
  final albumRepo = MockAlbumMemoryRepo();
  final shareRepo = MockShareMemoryRepo();

  await Remove(fileRepo, albumRepo, shareRepo, appDb, pref)(
      account, [files[0]]);
  expect(fileRepo.files, [files[1]]);
}

/// Remove a file, skip clean up
///
/// Expect: file deleted
Future<void> _removeFileNoCleanUp() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test2.jpg"))
      .build();
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final fileRepo = MockFileMemoryRepo(files);

  await Remove(fileRepo, null, null, null, null)(account, [files[0]]);
  expect(fileRepo.files, [files[1]]);
}

/// Remove a file included in an album
///
/// Expect: file removed from album
Future<void> _removeAlbumFile() async {
  final account = util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()..addFileItem(files[0])).build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo();

  await Remove(fileRepo, albumRepo, shareRepo, appDb, pref)(
      account, [files[0]]);
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

/// Remove a file included in an album
///
/// Expect: file not removed from album
Future<void> _removeAlbumFileNoCleanUp() async {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()..addFileItem(files[0])).build();
  final fileItems = util.AlbumBuilder.fileItemsOf(album);
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);
  final albumRepo = MockAlbumMemoryRepo([album]);

  await Remove(fileRepo, null, null, null, null)(account, [files[0]]);
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
          items: fileItems,
          latestItemTime: files[0].lastModified,
        ),
        coverProvider: AlbumAutoCoverProvider(coverFile: files[0]),
        sortProvider: const AlbumNullSortProvider(),
        albumFile: albumFile,
      ),
    ],
  );
}

/// Remove a file included in a shared album (admin -> user1)
///
/// Expect: file removed from album;
/// file share (admin -> user1) deleted
Future<void> _removeSharedAlbumFile() async {
  final account = util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1"))
      .build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    util.buildShare(id: "1", file: files[0], shareWith: "user1"),
  ]);

  await Remove(fileRepo, albumRepo, shareRepo, appDb, pref)(
      account, [files[0]]);
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
        shares: [
          util.buildAlbumShare(userId: "user1"),
        ],
      ),
    ],
  );
  expect(
    shareRepo.shares,
    [util.buildShare(id: "0", file: albumFile, shareWith: "user1")],
  );
}

/// Remove a file shared with you (user1 -> admin), added by you to a shared
/// album (admin -> user1, user2)
///
/// Expect: file removed from album;
/// file share (admin -> user2) deleted
Future<void> _removeSharedAlbumSharedFile() async {
  final account = util.buildAccount();
  final user1Account = util.buildAccount(username: "user1");
  final pref = Pref.scoped(PrefMemoryProvider());
  final files = (util.FilesBuilder(initialFileId: 1)
        ..addJpeg("admin/test1.jpg", ownerId: "user1"))
      .build();
  final user1Files = [
    files[0].copyWith(path: "remote.php/dav/files/user1/test1.jpg")
  ];
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1")
        ..addShare("user2"))
      .build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  await util.fillAppDb(appDb, user1Account, user1Files);
  final fileRepo = MockFileMemoryRepo([albumFile, ...files, ...user1Files]);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
    util.buildShare(
        id: "2", file: user1Files[0], uidOwner: "user1", shareWith: "admin"),
    util.buildShare(id: "3", file: files[0], shareWith: "user2"),
  ]);

  await Remove(fileRepo, albumRepo, shareRepo, appDb, pref)(
      account, [files[0]]);
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
        shares: [
          util.buildAlbumShare(userId: "user1"),
          util.buildAlbumShare(userId: "user2"),
        ],
      ),
    ],
  );
  expect(
    shareRepo.shares,
    [
      util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
      util.buildShare(
          id: "2", file: user1Files[0], uidOwner: "user1", shareWith: "admin"),
    ],
  );
}

/// Remove a file included in a shared album (admin -> user1), with the album
/// json updated by user1
///
/// Expect: file removed from album;
/// file share (admin -> user1) deleted
Future<void> _removeSharedAlbumResyncedFile() async {
  final account = util.buildAccount();
  final pref = Pref.scoped(PrefMemoryProvider());
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0]
            .copyWith(path: "remote.php/dav/files/user1/share/test1.jpg"))
        ..addShare("user1"))
      .build();
  final albumFile = album.albumFile!;
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);
  final fileRepo = MockFileMemoryRepo([albumFile, ...files]);
  final albumRepo = MockAlbumMemoryRepo([album]);
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    util.buildShare(id: "1", file: files[0], shareWith: "user1"),
  ]);

  await Remove(fileRepo, albumRepo, shareRepo, appDb, pref)(
      account, [files[0]]);
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
        shares: [
          util.buildAlbumShare(userId: "user1"),
        ],
      ),
    ],
  );
  expect(
    shareRepo.shares,
    [util.buildShare(id: "0", file: albumFile, shareWith: "user1")],
  );
}
