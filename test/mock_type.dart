import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:event_bus/event_bus.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/or_null.dart';

/// Mock of [AlbumRepo] where all methods will throw UnimplementedError
class MockAlbumRepo implements AlbumRepo {
  @override
  Future<void> cleanUp(Account account, String rootDir, List<File> albumFiles) {
    throw UnimplementedError();
  }

  @override
  Future<Album> create(Account account, Album album) {
    throw UnimplementedError();
  }

  @override
  AlbumDataSource get dataSrc => throw UnimplementedError();

  @override
  Future<Album> get(Account account, File albumFile) {
    throw UnimplementedError();
  }

  @override
  Future<void> update(Account account, Album album) {
    throw UnimplementedError();
  }
}

/// [AlbumRepo] mock that support some ops with an internal List
class MockAlbumMemoryRepo extends MockAlbumRepo {
  MockAlbumMemoryRepo([
    List<Album> initialData = const [],
  ]) : albums = List.of(initialData);

  @override
  get(Account account, File albumFile) async {
    return albums.firstWhere((element) =>
        element.albumFile?.compareServerIdentity(albumFile) == true);
  }

  @override
  update(Account account, Album album) async {
    final i = albums.indexWhere((element) =>
        element.albumFile?.compareServerIdentity(album.albumFile!) == true);
    albums[i] = album;
  }

  Album findAlbumByPath(String path) =>
      albums.firstWhere((element) => element.albumFile?.path == path);

  final List<Album> albums;
}

/// Each MockAppDb instance contains a unique memory database
class MockAppDb implements AppDb {
  @override
  Future<T> use<T>(FutureOr<T> Function(Database) fn) async {
    final db = await _dbFactory.open(
      "test.db",
      version: 1,
      onUpgradeNeeded: (event) async {
        final db = event.database;
        final albumStore = db.createObjectStore(AppDb.albumStoreName);
        albumStore.createIndex(
            AppDbAlbumEntry.indexName, AppDbAlbumEntry.keyPath);
        final fileDbStore = db.createObjectStore(AppDb.fileDbStoreName);
        fileDbStore.createIndex(
            AppDbFileDbEntry.indexName, AppDbFileDbEntry.keyPath,
            unique: false);
        final fileStore = db.createObjectStore(AppDb.fileStoreName);
        fileStore.createIndex(AppDbFileEntry.indexName, AppDbFileEntry.keyPath);
      },
    );

    try {
      return await fn(db);
    } finally {
      db.close();
    }
  }

  late final _dbFactory = newIdbFactoryMemory();
}

/// EventBus that ignore all events
class MockEventBus implements EventBus {
  @override
  destroy() {}

  @override
  fire(event) {}

  @override
  Stream<T> on<T>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  @override
  StreamController get streamController => _streamController;

  final _streamController = StreamController.broadcast();
}

/// Mock of [FileRepo] where all methods will throw UnimplementedError
class MockFileRepo implements FileRepo {
  @override
  Future<void> copy(Object account, File f, String destination,
      {bool? shouldOverwrite}) {
    throw UnimplementedError();
  }

  @override
  Future<void> createDir(Account account, String path) {
    throw UnimplementedError();
  }

  @override
  FileDataSource get dataSrc => throw UnimplementedError();

  @override
  Future<Uint8List> getBinary(Account account, File file) {
    throw UnimplementedError();
  }

  @override
  Future<List<File>> list(Account account, File root) async {
    throw UnimplementedError();
  }

  @override
  Future<File> listSingle(Account account, File root) async {
    throw UnimplementedError();
  }

  @override
  Future<void> move(Account account, File f, String destination,
      {bool? shouldOverwrite}) {
    throw UnimplementedError();
  }

  @override
  Future<void> putBinary(Account account, String path, Uint8List content) {
    throw UnimplementedError();
  }

  @override
  Future<void> remove(Account account, File file) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProperty(Account account, File file,
      {OrNull<Metadata>? metadata,
      OrNull<bool>? isArchived,
      OrNull<DateTime>? overrideDateTime}) {
    throw UnimplementedError();
  }
}

/// [FileRepo] mock that support some ops with an internal List
class MockFileMemoryRepo extends MockFileRepo {
  MockFileMemoryRepo([
    List<File> initialData = const [],
  ]) : files = List.of(initialData) {
    _id = files
            .where((f) => f.fileId != null)
            .map((f) => f.fileId!)
            .fold(-1, math.max) +
        1;
  }

  @override
  list(Account account, File root) async {
    return files.where((f) => file_util.isOrUnderDir(f, root)).toList();
  }

  final List<File> files;
  var _id = 0;
}

/// Mock of [ShareRepo] where all methods will throw UnimplementedError
class MockShareRepo implements ShareRepo {
  @override
  Future<Share> create(Account account, File file, String shareWith) {
    throw UnimplementedError();
  }

  @override
  Future<Share> createLink(Account account, File file, {String? password}) {
    throw UnimplementedError();
  }

  @override
  ShareDataSource get dataSrc => throw UnimplementedError();

  @override
  Future<void> delete(Account account, Share share) {
    throw UnimplementedError();
  }

  @override
  Future<List<Share>> list(Account account, File file) {
    throw UnimplementedError();
  }

  @override
  Future<List<Share>> listAll(Account account) {
    throw UnimplementedError();
  }

  @override
  Future<List<Share>> listDir(Account account, File dir) {
    throw UnimplementedError();
  }

  @override
  Future<List<Share>> reverseList(Account account, File file) {
    throw UnimplementedError();
  }

  @override
  Future<List<Share>> reverseListAll(Account account) {
    throw UnimplementedError();
  }
}

/// [ShareRepo] mock that support some ops with an internal List
class MockShareMemoryRepo extends MockShareRepo {
  MockShareMemoryRepo([
    List<Share> initialData = const [],
  ]) : shares = List.of(initialData) {
    _id = shares.map((e) => int.parse(e.id)).fold(-1, math.max) + 1;
  }

  @override
  list(Account account, File file) async {
    return shares
        .where((element) =>
            element.path == file.strippedPath &&
            element.uidOwner == account.username)
        .toList();
  }

  @override
  create(Account account, File file, String shareWith) async {
    final share = Share(
      id: (_id++).toString(),
      shareType: ShareType.user,
      stime: DateTime.utc(2020, 1, 2, 3, 4, 5),
      uidOwner: account.username,
      displaynameOwner: account.username.toString(),
      path: file.strippedPath,
      itemType: ShareItemType.file,
      mimeType: file.contentType ?? "",
      itemSource: file.fileId!,
      shareWith: shareWith.toCi(),
      shareWithDisplayName: shareWith,
    );
    shares.add(share);
    return share;
  }

  @override
  delete(Account account, Share share) async {
    shares.removeWhere((s) => s.id == share.id);
  }

  final List<Share> shares;
  var _id = 0;
}

/// Mock of [ShareeRepo] where all methods will throw UnimplementedError
class MockShareeRepo implements ShareeRepo {
  @override
  ShareeDataSource get dataSrc => throw UnimplementedError();

  @override
  Future<List<Sharee>> list(Account account) {
    throw UnimplementedError();
  }
}

class MockShareeMemoryRepo extends MockShareeRepo {
  MockShareeMemoryRepo([
    List<Sharee> initialData = const [],
  ]) : sharees = List.of(initialData);

  @override
  list(Account account) async {
    return sharees.where((s) => s.shareWith != account.username).toList();
  }

  final List<Sharee> sharees;
}
