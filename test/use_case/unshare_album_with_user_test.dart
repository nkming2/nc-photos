import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/use_case/unshare_album_with_user.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as test_util;

void main() {
  KiwiContainer().registerInstance<EventBus>(MockEventBus());

  group("UnshareAlbumWithUser", () {
    test("w/o file", _unshareWithoutFile);
    test("w/ file", _unshareWithFile);
    test("w/ file not owned", _unshareWithFileNotOwned);
  });
}

/// Unshare an empty album with a user (user1)
///
/// Expect: user (admin -> user1) removed from album's shares list;
/// share (admin -> user1) for the album json deleted
Future<void> _unshareWithoutFile() async {
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
      shares: [
        AlbumShare(userId: "user1".toCi()),
        AlbumShare(userId: "user2".toCi()),
      ],
      albumFile: albumFile,
    ),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    test_util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
  ]);

  await UnshareAlbumWithUser(shareRepo, fileRepo, albumRepo)(
      account, albumRepo.findAlbumByPath(albumFile.path), "user1".toCi());
  expect(albumRepo.findAlbumByPath(albumFile.path).shares,
      [AlbumShare(userId: "user2".toCi())]);
  expect(
    shareRepo.shares,
    [test_util.buildShare(id: "1", file: albumFile, shareWith: "user2")],
  );
}

/// Unshare an album with a user (user1)
///
/// Expect: user (admin -> user1) removed from album's shares list;
/// share (admin -> user1) for the album json deleted;
/// shares (admin -> user1) for the album files deleted
Future<void> _unshareWithFile() async {
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
      shares: [
        AlbumShare(userId: "user1".toCi()),
        AlbumShare(userId: "user2".toCi()),
      ],
      albumFile: albumFile,
    ),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    test_util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
    test_util.buildShare(id: "2", file: file1, shareWith: "user1"),
    test_util.buildShare(id: "3", file: file1, shareWith: "user2"),
  ]);

  await UnshareAlbumWithUser(shareRepo, fileRepo, albumRepo)(
      account, albumRepo.findAlbumByPath(albumFile.path), "user1".toCi());
  expect(albumRepo.findAlbumByPath(albumFile.path).shares,
      [AlbumShare(userId: "user2".toCi())]);
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
      test_util.buildShare(id: "3", file: file1, shareWith: "user2"),
    ],
  );
}

/// Unshare an album with a user (user1), where some files are not owned by us
/// (admin)
///
/// Expect: user (admin -> user1) removed from album's shares list;
/// share (admin -> user1) for the album json deleted;
/// shares (admin -> user1) for the owned album files deleted;
/// shares (user2 -> user1) created by other unchanged
Future<void> _unshareWithFileNotOwned() async {
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
  final file2 = test_util.buildJpegFile(
    path: "remote.php/dav/files/user2/test2.jpg",
    fileId: 2,
    lastModified: DateTime.utc(2020, 1, 2, 3, 4, 6),
    ownerId: "user2",
  );
  final fileItem2 = AlbumFileItem(
    file: file2,
    addedBy: "user2".toCi(),
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 6),
  );
  final albumRepo = MockAlbumMemoryRepo([
    Album(
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test",
      provider: AlbumStaticProvider(
        items: [fileItem1, fileItem2],
        latestItemTime: file2.lastModified,
      ),
      coverProvider: AlbumAutoCoverProvider(coverFile: file2),
      sortProvider: const AlbumNullSortProvider(),
      shares: [
        AlbumShare(userId: "user1".toCi()),
        AlbumShare(userId: "user2".toCi()),
      ],
      albumFile: albumFile,
    ),
  ]);
  final fileRepo = MockFileMemoryRepo([albumFile, file1]);
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
    test_util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
    test_util.buildShare(id: "2", file: file1, shareWith: "user1"),
    test_util.buildShare(id: "3", file: file1, shareWith: "user2"),
    test_util.buildShare(
        id: "4", uidOwner: "user2", file: file2, shareWith: "admin"),
    test_util.buildShare(
        id: "5", uidOwner: "user2", file: file2, shareWith: "user1"),
  ]);

  await UnshareAlbumWithUser(shareRepo, fileRepo, albumRepo)(
      account, albumRepo.findAlbumByPath(albumFile.path), "user1".toCi());
  expect(albumRepo.findAlbumByPath(albumFile.path).shares,
      [AlbumShare(userId: "user2".toCi())]);
  expect(
    shareRepo.shares,
    [
      test_util.buildShare(id: "1", file: albumFile, shareWith: "user2"),
      test_util.buildShare(id: "3", file: file1, shareWith: "user2"),
      test_util.buildShare(
          id: "4", uidOwner: "user2", file: file2, shareWith: "admin"),
      test_util.buildShare(
          id: "5", uidOwner: "user2", file: file2, shareWith: "user1"),
    ],
  );
}
