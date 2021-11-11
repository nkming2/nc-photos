import 'package:bloc_test/bloc_test.dart';
import 'package:nc_photos/bloc/list_album_share_outlier.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as test_util;

void main() {
  group("ListAlbumShareOutlierBloc", () {
    test("intial state", _initialState);
    group("ListAlbumShareOutlierBlocQuery", () {
      group("unshared album", () {
        _testQueryUnsharedAlbumExtraFileShare();
        _testQueryUnsharedAlbumExtraJsonShare();
      });
      group("shared album", () {
        _testQuerySharedAlbumMissingFileShare();
        _testQuerySharedAlbumMissingJsonShare();
      });
    });
  });
}

void _initialState() {
  final shareRepo = MockShareRepo();
  final shareeRepo = MockShareeRepo();
  final bloc = ListAlbumShareOutlierBloc(shareRepo, shareeRepo);
  expect(bloc.state.account, null);
  expect(bloc.state.items, const []);
}

/// Query an album that is not shared, but with shared file (admin -> user1)
///
/// Expect: emit the file with extra share (admin -> user1)
void _testQueryUnsharedAlbumExtraFileShare() {
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
    addedBy: "admin",
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final album = Album(
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test",
    provider: AlbumStaticProvider(
      items: [fileItem1],
      latestItemTime: file1.lastModified,
    ),
    coverProvider: AlbumAutoCoverProvider(coverFile: file1),
    sortProvider: const AlbumNullSortProvider(),
    albumFile: albumFile,
  );
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: file1, shareWith: "user1"),
  ]);
  final shareeRepo = MockShareeMemoryRepo([
    test_util.buildSharee(shareWith: "user1"),
  ]);
  blocTest<ListAlbumShareOutlierBloc, ListAlbumShareOutlierBlocState>(
    "extra file share",
    build: () => ListAlbumShareOutlierBloc(shareRepo, shareeRepo),
    act: (bloc) => bloc.add(ListAlbumShareOutlierBlocQuery(account, album)),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      ListAlbumShareOutlierBlocLoading(account, []),
      ListAlbumShareOutlierBlocSuccess(account, [
        ListAlbumShareOutlierItem(file1, [
          ListAlbumShareOutlierExtraShareItem(
              test_util.buildShare(id: "0", file: file1, shareWith: "user1")),
        ]),
      ]),
    ],
  );
}

/// Query an album that is not shared, but the album json is shared
/// (admin -> user1)
///
/// Expect: emit the json file with extra share (admin -> user1)
void _testQueryUnsharedAlbumExtraJsonShare() {
  final account = test_util.buildAccount();
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final album = Album(
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test",
    provider: AlbumStaticProvider(items: []),
    coverProvider: AlbumAutoCoverProvider(),
    sortProvider: const AlbumNullSortProvider(),
    albumFile: albumFile,
  );
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
  ]);
  final shareeRepo = MockShareeMemoryRepo([
    test_util.buildSharee(shareWith: "user1"),
  ]);
  blocTest<ListAlbumShareOutlierBloc, ListAlbumShareOutlierBlocState>(
    "extra json share",
    build: () => ListAlbumShareOutlierBloc(shareRepo, shareeRepo),
    act: (bloc) => bloc.add(ListAlbumShareOutlierBlocQuery(account, album)),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      ListAlbumShareOutlierBlocLoading(account, []),
      ListAlbumShareOutlierBlocSuccess(account, [
        ListAlbumShareOutlierItem(albumFile, [
          ListAlbumShareOutlierExtraShareItem(test_util.buildShare(
              id: "0", file: albumFile, shareWith: "user1")),
        ]),
      ]),
    ],
  );
}

/// Query a shared album (admin -> user1), with file not shared
///
/// Expect: emit the file with missing share (admin -> user1)
void _testQuerySharedAlbumMissingFileShare() {
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
    addedBy: "admin",
    addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
  );
  final album = Album(
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test",
    provider: AlbumStaticProvider(
      items: [fileItem1],
      latestItemTime: file1.lastModified,
    ),
    coverProvider: AlbumAutoCoverProvider(coverFile: file1),
    sortProvider: const AlbumNullSortProvider(),
    shares: [const AlbumShare(userId: "user1")],
    albumFile: albumFile,
  );
  final shareRepo = MockShareMemoryRepo([
    test_util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
  ]);
  final shareeRepo = MockShareeMemoryRepo([
    test_util.buildSharee(shareWith: "user1"),
  ]);
  blocTest<ListAlbumShareOutlierBloc, ListAlbumShareOutlierBlocState>(
    "missing file share",
    build: () => ListAlbumShareOutlierBloc(shareRepo, shareeRepo),
    act: (bloc) => bloc.add(ListAlbumShareOutlierBlocQuery(account, album)),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      ListAlbumShareOutlierBlocLoading(account, []),
      ListAlbumShareOutlierBlocSuccess(account, [
        ListAlbumShareOutlierItem(file1, [
          const ListAlbumShareOutlierMissingShareItem("user1", null),
        ]),
      ]),
    ],
  );
}

/// Query a shared album (admin -> user1), with album json not shared
///
/// Expect: emit the file with missing share (admin -> user1)
void _testQuerySharedAlbumMissingJsonShare() {
  final account = test_util.buildAccount();
  final albumFile = test_util.buildAlbumFile(
    path: test_util.buildAlbumFilePath("test1.json"),
    fileId: 0,
  );
  final album = Album(
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test",
    provider: AlbumStaticProvider(items: []),
    coverProvider: AlbumAutoCoverProvider(),
    sortProvider: const AlbumNullSortProvider(),
    shares: [const AlbumShare(userId: "user1")],
    albumFile: albumFile,
  );
  final shareRepo = MockShareMemoryRepo();
  final shareeRepo = MockShareeMemoryRepo([
    test_util.buildSharee(shareWith: "user1"),
  ]);
  blocTest<ListAlbumShareOutlierBloc, ListAlbumShareOutlierBlocState>(
    "missing json share",
    build: () => ListAlbumShareOutlierBloc(shareRepo, shareeRepo),
    act: (bloc) => bloc.add(ListAlbumShareOutlierBlocQuery(account, album)),
    wait: const Duration(milliseconds: 500),
    expect: () => [
      ListAlbumShareOutlierBlocLoading(account, []),
      ListAlbumShareOutlierBlocSuccess(account, [
        ListAlbumShareOutlierItem(albumFile, [
          const ListAlbumShareOutlierMissingShareItem("user1", null),
        ]),
      ]),
    ],
  );
}
