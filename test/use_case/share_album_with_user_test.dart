import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/use_case/share_album_with_user.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as test_util;

void main() {
  KiwiContainer().registerInstance<EventBus>(MockEventBus());

  group("ShareAlbumWithUser", () {
    test("w/o file", _shareWithoutFile);
    test("w/ file", _shareWithFile);
    test("w/ file owned by user", _shareWithFileOwnedByUser);
    test("shared album", _shareSharedAlbum);
  });
}

/// Share an empty album with a user (user1)
///
/// Expect: share (admin -> user1) added to album's shares list;
/// a new share (admin -> user1) is created for the album json
Future<void> _shareWithoutFile() async {
  final account = test_util.buildAccount();
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(items: []),
      coverProvider: AlbumAutoCoverProvider(),
      sortProvider: const AlbumNullSortProvider(),
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareMemoryRepo();

  await ShareAlbumWithUser(shareRepo, albumRepo)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    test_util.buildSharee(shareWith: "user1".toCi()),
  );
  expect(
    albumRepo.findAlbumByPath(albumFile.path).shares,
    [AlbumShare(userId: "user1".toCi())],
  );
  expect(
    shareRepo.shares,
    [test_util.buildShare(id: "0", file: albumFile, shareWith: "user1")],
  );
}

/// Share an album with files to a user (user1)
///
/// Expect: share (admin -> user1) added to album's shares list;
/// new shares (admin -> user1) are created for the album json and the album
/// files
Future<void> _shareWithFile() async {
  final account = test_util.buildAccount();
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
  final shareRepo = MockShareMemoryRepo();

  await ShareAlbumWithUser(shareRepo, albumRepo)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    test_util.buildSharee(shareWith: "user1".toCi()),
  );
  expect(
    albumRepo.findAlbumByPath(albumFile.path).shares,
    [AlbumShare(userId: "user1".toCi())],
  );
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      test_util.buildShare(id: "1", file: file1, shareWith: "user1"),
    ],
  );
}

/// Share an album with files owned by user (user1) to that user (user1)
///
/// Expect: share (admin -> user1) added to album's shares list;
/// new shares (admin -> user1) are created for the album json
Future<void> _shareWithFileOwnedByUser() async {
  final account = test_util.buildAccount();
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final file1 = test_util.buildJpegFile(
    path: "remote.php/dav/files/admin/test1.jpg",
    fileId: 1,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5),
    ownerId: "user1"
  );
  final fileItem1 = AlbumFileItem(
    file: file1,
    addedBy: "admin".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
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
  final shareRepo = MockShareMemoryRepo();

  await ShareAlbumWithUser(shareRepo, albumRepo)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    test_util.buildSharee(shareWith: "user1".toCi()),
  );
  expect(
    albumRepo.findAlbumByPath(albumFile.path).shares,
    [AlbumShare(userId: "user1".toCi())],
  );
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    ],
  );
}

/// Share a shared album (admin -> user1) with a user (user2)
///
/// Expect: share (admin -> user2) added to album's shares list;
/// a new share (admin -> user2) is created for the album json
Future<void> _shareSharedAlbum() async {
  final account = test_util.buildAccount();
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(items: []),
      coverProvider: AlbumAutoCoverProvider(),
      sortProvider: const AlbumNullSortProvider(),
      shares: [AlbumShare(userId: "user1".toCi())],
      albumFile: albumFile,
    ),
  ]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
  ]);

  await ShareAlbumWithUser(shareRepo, albumRepo)(
    account,
    albumRepo.findAlbumByPath(albumFile.path),
    test_util.buildSharee(shareWith: "user2".toCi()),
  );
  expect(
    albumRepo.findAlbumByPath(albumFile.path).shares,
    [
      AlbumShare(userId: "user1".toCi()),
      AlbumShare(userId: "user2".toCi()),
    ],
  );
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
      test_util.buildShare(id: "1", file: albumFile, shareWith: "user2")
    ],
  );
}
