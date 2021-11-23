import 'package:bloc_test/bloc_test.dart';
import 'package:nc_photos/bloc/list_album_share_outlier.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as util;

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
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()..addFileItem(files[0])).build();
  final file1 = files[0];
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: file1, shareWith: "user1"),
  ]);
  final shareeRepo = MockShareeMemoryRepo([
    util.buildSharee(shareWith: "user1".toCi()),
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
              util.buildShare(id: "0", file: file1, shareWith: "user1")),
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
  final account = util.buildAccount();
  final album = util.AlbumBuilder().build();
  final albumFile = album.albumFile!;
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
  ]);
  final shareeRepo = MockShareeMemoryRepo([
    util.buildSharee(shareWith: "user1".toCi()),
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
          ListAlbumShareOutlierExtraShareItem(
              util.buildShare(id: "0", file: albumFile, shareWith: "user1")),
        ]),
      ]),
    ],
  );
}

/// Query a shared album (admin -> user1), with file not shared
///
/// Expect: emit the file with missing share (admin -> user1)
void _testQuerySharedAlbumMissingFileShare() {
  final account = util.buildAccount();
  final files =
      (util.FilesBuilder(initialFileId: 1)..addJpeg("admin/test1.jpg")).build();
  final album = (util.AlbumBuilder()
        ..addFileItem(files[0])
        ..addShare("user1"))
      .build();
  final file1 = files[0];
  final albumFile = album.albumFile!;
  final shareRepo = MockShareMemoryRepo([
    util.buildShare(id: "0", file: albumFile, shareWith: "user1"),
  ]);
  final shareeRepo = MockShareeMemoryRepo([
    util.buildSharee(shareWith: "user1".toCi()),
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
          ListAlbumShareOutlierMissingShareItem("user1".toCi(), "user1"),
        ]),
      ]),
    ],
  );
}

/// Query a shared album (admin -> user1), with album json not shared
///
/// Expect: emit the file with missing share (admin -> user1)
void _testQuerySharedAlbumMissingJsonShare() {
  final account = util.buildAccount();
  final album = (util.AlbumBuilder()..addShare("user1")).build();
  final albumFile = album.albumFile!;
  final shareRepo = MockShareMemoryRepo();
  final shareeRepo = MockShareeMemoryRepo([
    util.buildSharee(shareWith: "user1".toCi()),
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
          ListAlbumShareOutlierMissingShareItem("user1".toCi(), "user1"),
        ]),
      ]),
    ],
  );
}
