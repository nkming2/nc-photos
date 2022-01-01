import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:event_bus/event_bus.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/di_container.dart';
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
  ]) : albums = initialData.map((a) => a.copyWith()).toList();

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
  static Future<MockAppDb> create({
    bool hasAlbumStore = true,
    bool hasFileDb2Store = true,
    bool hasDirStore = true,
    // compat
    bool hasFileStore = false,
    bool hasFileDbStore = false,
  }) async {
    final inst = MockAppDb();
    final db = await inst._dbFactory.open(
      "test.db",
      version: 1,
      onUpgradeNeeded: (event) async {
        final db = event.database;
        _createDb(
          db,
          hasAlbumStore: hasAlbumStore,
          hasFileDb2Store: hasFileDb2Store,
          hasDirStore: hasDirStore,
          hasFileStore: hasFileStore,
          hasFileDbStore: hasFileDbStore,
        );
      },
    );
    db.close();
    return inst;
  }

  @override
  Future<T> use<T>(FutureOr<T> Function(Database) fn) async {
    final db = await _dbFactory.open(
      "test.db",
      version: 1,
      onUpgradeNeeded: (event) async {
        final db = event.database;
        _createDb(db);
      },
    );

    try {
      return await fn(db);
    } finally {
      db.close();
    }
  }

  static void _createDb(
    Database db, {
    bool hasAlbumStore = true,
    bool hasFileDb2Store = true,
    bool hasDirStore = true,
    // compat
    bool hasFileStore = false,
    bool hasFileDbStore = false,
  }) {
    if (hasAlbumStore) {
      final albumStore = db.createObjectStore(AppDb.albumStoreName);
      albumStore.createIndex(
          AppDbAlbumEntry.indexName, AppDbAlbumEntry.keyPath);
    }
    if (hasFileDb2Store) {
      final file2Store = db.createObjectStore(AppDb.file2StoreName);
      file2Store.createIndex(AppDbFile2Entry.strippedPathIndexName,
          AppDbFile2Entry.strippedPathKeyPath);
    }
    if (hasDirStore) {
      db.createObjectStore(AppDb.dirStoreName);
    }

    // compat
    if (hasFileStore) {
      final fileStore = db.createObjectStore(_fileStoreName);
      fileStore.createIndex(_fileIndexName, _fileKeyPath);
    }
    if (hasFileDbStore) {
      final fileDbStore = db.createObjectStore(_fileDbStoreName);
      fileDbStore.createIndex(_fileDbIndexName, _fileDbKeyPath, unique: false);
    }
  }

  late final _dbFactory = newIdbFactoryMemory();

  // compat only
  static const _fileDbStoreName = "filesDb";
  static const _fileDbIndexName = "fileDbStore_namespacedFileId";
  static const _fileDbKeyPath = "namespacedFileId";

  static const _fileStoreName = "files";
  static const _fileIndexName = "fileStore_path_index";
  static const _fileKeyPath = ["path", "index"];
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
  ]) : files = initialData.map((f) => f.copyWith()).toList() {
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

  @override
  remove(Account account, File file) async {
    files.removeWhere((f) {
      if (file.isCollection == true) {
        return file_util.isOrUnderDir(f, file);
      } else {
        return f.compareServerIdentity(file);
      }
    });
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
  Future<List<Share>> list(
    Account account,
    File file, {
    bool? isIncludeReshare,
  }) {
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
  list(
    Account account,
    File file, {
    bool? isIncludeReshare,
  }) async {
    return shares.where((s) {
      if (s.itemSource != file.fileId) {
        return false;
      } else if (isIncludeReshare == true || s.uidOwner == account.username) {
        return true;
      } else {
        return false;
      }
    }).toList();
  }

  @override
  create(Account account, File file, String shareWith) async {
    final share = Share(
      id: (_id++).toString(),
      shareType: ShareType.user,
      stime: DateTime.utc(2020, 1, 2, 3, 4, 5),
      uidOwner: account.username,
      displaynameOwner: account.username.toString(),
      uidFileOwner: file.ownerId!,
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

extension MockDiContainerExtension on DiContainer {
  MockAlbumMemoryRepo get albumMemoryRepo => albumRepo as MockAlbumMemoryRepo;
  MockFileMemoryRepo get fileMemoryRepo => fileRepo as MockFileMemoryRepo;
  MockShareMemoryRepo get shareMemoryRepo => shareRepo as MockShareMemoryRepo;
  MockShareeMemoryRepo get shareeMemoryRepo =>
      shareeRepo as MockShareeMemoryRepo;

  MockAppDb get appMemeoryDb => appDb as MockAppDb;
}
