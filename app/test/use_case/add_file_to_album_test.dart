import 'package:clock/clock.dart';
import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/entity/pref/provider/memory.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/use_case/album/add_file_to_album.dart';
import 'package:np_common/ci_string.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as util;

void main() {
  KiwiContainer().registerInstance<EventBus>(MockEventBus());

  group("AddFileToAlbum", () {
    test("file", _addFile);
    test("ignore existing file", _addExistingFile);
    test("ignore existing file (shared)", _addExistingSharedFile);
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
  await withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () async {
    final account = util.buildAccount();
    final file = (util.FilesBuilder(initialFileId: 1)
          ..addJpeg("admin/test1.jpg"))
        .build()[0];
    final album = util.AlbumBuilder().build();
    final albumFile = album.albumFile!;
    final c = DiContainer(
      fileRepo: MockFileMemoryRepo(),
      albumRepo: MockAlbumMemoryRepo([album]),
      shareRepo: MockShareRepo(),
      sqliteDb: util.buildTestDb(),
      pref: Pref.scoped(PrefMemoryProvider()),
    );
    addTearDown(() => c.sqliteDb.close());
    await c.sqliteDb.transaction(() async {
      await c.sqliteDb.insertAccountOf(account);
      await util.insertFiles(c.sqliteDb, account, [file]);
    });

    await AddFileToAlbum(c)(
      account,
      c.albumMemoryRepo.findAlbumByPath(albumFile.path),
      [file],
    );
    expect(
      c.albumMemoryRepo.albums,
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
              ).minimize(),
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
  });
}

/// Add a [File], already included in the [Album], to an [Album]
///
/// Expect: file not added to album
Future<void> _addExistingFile() async {
  await withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () async {
    final account = util.buildAccount();
    final files = (util.FilesBuilder(initialFileId: 1)
          ..addJpeg(
            "admin/test1.jpg",
            lastModified: DateTime.utc(2019, 1, 2, 3, 4, 5),
          ))
        .build();
    final album = (util.AlbumBuilder()
          ..addFileItem(
            files[0],
            addedAt: clock.now().toUtc(),
          ))
        .build();
    final oldFile = files[0];
    final newFile = files[0].copyWith();
    final albumFile = album.albumFile!;
    final c = DiContainer(
      fileRepo: MockFileMemoryRepo(),
      albumRepo: MockAlbumMemoryRepo([album]),
      shareRepo: MockShareRepo(),
      sqliteDb: util.buildTestDb(),
      pref: Pref.scoped(PrefMemoryProvider()),
    );
    addTearDown(() => c.sqliteDb.close());
    await c.sqliteDb.transaction(() async {
      await c.sqliteDb.insertAccountOf(account);
      await util.insertFiles(c.sqliteDb, account, files);
    });

    await AddFileToAlbum(c)(
      account,
      c.albumMemoryRepo.findAlbumByPath(albumFile.path),
      [newFile],
    );
    expect(
      c.albumMemoryRepo.albums,
      [
        Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
          name: "test",
          provider: AlbumStaticProvider(
            items: [
              AlbumFileItem(
                addedBy: "admin".toCi(),
                addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
                file: files[0],
              ),
            ],
            latestItemTime: DateTime.utc(2019, 1, 2, 3, 4, 5),
          ),
          coverProvider: AlbumAutoCoverProvider(coverFile: files[0]),
          sortProvider: const AlbumNullSortProvider(),
          albumFile: albumFile,
        ),
      ],
    );
    // when there's a conflict, it's guaranteed that the original file in the
    // album is kept and the incoming file dropped
    expect(
        identical(
            AlbumStaticProvider.of(c.albumMemoryRepo.albums[0])
                .items
                .whereType<AlbumFileItem>()
                .first
                .file,
            oldFile),
        true);
    expect(
        identical(
            AlbumStaticProvider.of(c.albumMemoryRepo.albums[0])
                .items
                .whereType<AlbumFileItem>()
                .first
                .file,
            newFile),
        false);
  });
}

/// Add a file shared with you to an album, where the file is already included
///
/// Expect: file not added to album
Future<void> _addExistingSharedFile() async {
  await withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () async {
    final account = util.buildAccount();
    final user1Account = util.buildAccount(userId: "user1");
    final files = (util.FilesBuilder(initialFileId: 1)
          ..addJpeg("admin/test1.jpg"))
        .build();
    final user1Files = [
      files[0].copyWith(path: "remote.php/dav/files/user1/test1.jpg")
    ];
    final album = (util.AlbumBuilder()..addFileItem(files[0])).build();
    final albumFile = album.albumFile!;
    final c = DiContainer(
      fileRepo: MockFileMemoryRepo(),
      albumRepo: MockAlbumMemoryRepo([album]),
      shareRepo: MockShareRepo(),
      sqliteDb: util.buildTestDb(),
      pref: Pref.scoped(PrefMemoryProvider()),
    );
    addTearDown(() => c.sqliteDb.close());
    await c.sqliteDb.transaction(() async {
      await c.sqliteDb.insertAccountOf(account);
      await c.sqliteDb.insertAccountOf(user1Account);
      await util.insertFiles(c.sqliteDb, account, files);
      await util.insertFiles(c.sqliteDb, user1Account, user1Files);
    });

    await AddFileToAlbum(c)(
      account,
      c.albumMemoryRepo.findAlbumByPath(albumFile.path),
      [user1Files[0]],
    );
    expect(
      c.albumMemoryRepo.albums,
      [
        Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
          name: "test",
          provider: AlbumStaticProvider(
            items: [
              AlbumFileItem(
                addedBy: "admin".toCi(),
                addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
                file: files[0],
              ),
            ],
            latestItemTime: DateTime.utc(2020, 1, 2, 3, 4, 5),
          ),
          coverProvider: AlbumAutoCoverProvider(coverFile: files[0]),
          sortProvider: const AlbumNullSortProvider(),
          albumFile: albumFile,
        ),
      ],
    );
  });
}

/// Add a file to a shared album (admin -> user1)
///
/// Expect: a new share (admin -> user1) is created for the file
Future<void> _addFileToSharedAlbumOwned() async {
  await withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () async {
    final account = util.buildAccount();
    final file = (util.FilesBuilder(initialFileId: 1)
          ..addJpeg("admin/test1.jpg"))
        .build()[0];
    final album = (util.AlbumBuilder()..addShare("user1")).build();
    final albumFile = album.albumFile!;
    final c = DiContainer(
      fileRepo: MockFileMemoryRepo(),
      albumRepo: MockAlbumMemoryRepo([album]),
      shareRepo: MockShareMemoryRepo([
        util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      ]),
      sqliteDb: util.buildTestDb(),
      pref: Pref.scoped(PrefMemoryProvider({
        "isLabEnableSharedAlbum": true,
      })),
    );
    addTearDown(() => c.sqliteDb.close());
    await c.sqliteDb.transaction(() async {
      await c.sqliteDb.insertAccountOf(account);
      await util.insertFiles(c.sqliteDb, account, [file]);
    });

    await AddFileToAlbum(c)(
      account,
      c.albumMemoryRepo.findAlbumByPath(albumFile.path),
      [file],
    );
    expect(
      c.shareMemoryRepo.shares,
      [
        util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
        util.buildShare(id: "1", file: file, shareWith: "user1"),
      ],
    );
  });
}

/// Add a file owned by user (user1) to a shared album (admin -> user1)
///
/// Expect: no shares created
Future<void> _addFileOwnedByUserToSharedAlbumOwned() async {
  await withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () async {
    final account = util.buildAccount();
    final file = (util.FilesBuilder(initialFileId: 1)
          ..addJpeg("admin/test1.jpg", ownerId: "user1"))
        .build()[0];
    final album = (util.AlbumBuilder()..addShare("user1")).build();
    final albumFile = album.albumFile!;
    final c = DiContainer(
      fileRepo: MockFileMemoryRepo(),
      albumRepo: MockAlbumMemoryRepo([album]),
      shareRepo: MockShareMemoryRepo([
        util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      ]),
      sqliteDb: util.buildTestDb(),
      pref: Pref.scoped(PrefMemoryProvider({
        "isLabEnableSharedAlbum": true,
      })),
    );
    addTearDown(() => c.sqliteDb.close());
    await c.sqliteDb.transaction(() async {
      await c.sqliteDb.insertAccountOf(account);
      await util.insertFiles(c.sqliteDb, account, [file]);
    });

    await AddFileToAlbum(c)(
      account,
      c.albumMemoryRepo.findAlbumByPath(albumFile.path),
      [file],
    );
    expect(
      c.shareMemoryRepo.shares,
      [
        util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      ],
    );
  });
}

/// Add a file to a shared album (user1 -> admin, user2)
///
/// Expect: a new share (admin -> user1, user2) is created for the file
Future<void> _addFileToMultiuserSharedAlbumNotOwned() async {
  await withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () async {
    // doesn't work right now, skipped
    final account = util.buildAccount();
    final file = (util.FilesBuilder(initialFileId: 1)
          ..addJpeg("admin/test1.jpg"))
        .build()[0];
    final album = (util.AlbumBuilder(ownerId: "user1")
          ..addShare("admin")
          ..addShare("user2"))
        .build();
    final albumFile = album.albumFile!;
    final c = DiContainer(
      fileRepo: MockFileMemoryRepo(),
      albumRepo: MockAlbumMemoryRepo([album]),
      shareRepo: MockShareMemoryRepo([
        util.buildShare(
            id: "0", file: albumFile, uidOwner: "user1", shareWith: "admin"),
        util.buildShare(
            id: "1", file: albumFile, uidOwner: "user1", shareWith: "user2"),
      ]),
      sqliteDb: util.buildTestDb(),
      pref: Pref.scoped(PrefMemoryProvider({
        "isLabEnableSharedAlbum": true,
      })),
    );
    addTearDown(() => c.sqliteDb.close());
    await c.sqliteDb.transaction(() async {
      await c.sqliteDb.insertAccountOf(account);
      await util.insertFiles(c.sqliteDb, account, [file]);
    });

    await AddFileToAlbum(c)(
      account,
      c.albumMemoryRepo.findAlbumByPath(albumFile.path),
      [file],
    );
    expect(
      c.shareMemoryRepo.shares,
      [
        util.buildShare(
            id: "0", uidOwner: "user1", file: albumFile, shareWith: "admin"),
        util.buildShare(
            id: "1", uidOwner: "user1", file: albumFile, shareWith: "user2"),
        // the order for these two shares are actually NOT guaranteed
        util.buildShare(id: "2", file: file, shareWith: "user2"),
        util.buildShare(id: "3", file: file, shareWith: "user1"),
      ],
    );
  });
}
