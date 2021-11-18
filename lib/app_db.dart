import 'dart:async';

import 'package:idb_shim/idb.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/type.dart';
import 'package:synchronized/synchronized.dart';

class AppDb {
  static const dbName = "app.db";
  static const dbVersion = 3;
  static const fileStoreName = "files";
  static const albumStoreName = "albums";

  /// this is a stupid name but 'files' is already being used so...
  static const fileDbStoreName = "filesDb";

  factory AppDb() => _inst;

  AppDb._();

  /// Run [fn] with an opened database instance
  ///
  /// This function guarantees that:
  /// 1) Database is always closed after [fn] exits, even with an error
  /// 2) Only at most 1 database instance being opened at any time
  Future<T> use<T>(FutureOr<T> Function(Database) fn) async {
    // make sure only one client is opening the db
    return await _lock.synchronized(() async {
      final db = await _open();
      try {
        return await fn(db);
      } finally {
        db.close();
      }
    });
  }

  /// Open the database
  Future<Database> _open() async {
    final dbFactory = platform.getDbFactory();
    return dbFactory.open(dbName, version: dbVersion,
        onUpgradeNeeded: (event) async {
      _log.info("[_open] Upgrade database: ${event.oldVersion} -> $dbVersion");

      final db = event.database;
      ObjectStore fileStore, albumStore, fileDbStore;
      if (event.oldVersion < 2) {
        // version 2 store things in a new way, just drop all
        try {
          db.deleteObjectStore(albumStoreName);
        } catch (_) {}
        albumStore = db.createObjectStore(albumStoreName);
        albumStore.createIndex(
            AppDbAlbumEntry.indexName, AppDbAlbumEntry.keyPath);
      }
      if (event.oldVersion < 3) {
        // new object store in v3
        try {
          db.deleteObjectStore(fileDbStoreName);
        } catch (_) {}
        fileDbStore = db.createObjectStore(fileDbStoreName);
        fileDbStore.createIndex(
            AppDbFileDbEntry.indexName, AppDbFileDbEntry.keyPath,
            unique: false);

        // recreate file store from scratch
        try {
          db.deleteObjectStore(fileStoreName);
        } catch (_) {}
        fileStore = db.createObjectStore(fileStoreName);
        fileStore.createIndex(AppDbFileEntry.indexName, AppDbFileEntry.keyPath);
      }
    });
  }

  static late final _inst = AppDb._();
  final _lock = Lock(reentrant: true);

  static final _log = Logger("app_db.AppDb");
}

class AppDbFileEntry {
  static const indexName = "fileStore_path_index";
  static const keyPath = ["path", "index"];
  static const maxDataSize = 160;

  AppDbFileEntry(this.path, this.index, this.data);

  JsonObj toJson() {
    return {
      "path": path,
      "index": index,
      "data": data.map((e) => e.toJson()).toList(),
    };
  }

  factory AppDbFileEntry.fromJson(JsonObj json) {
    return AppDbFileEntry(
      json["path"],
      json["index"],
      json["data"]
          .map((e) => File.fromJson(e.cast<String, dynamic>()))
          .cast<File>()
          .toList(),
    );
  }

  static String toPath(Account account, File dir) =>
      "${account.url}/${dir.path}";

  static String toPrimaryKey(Account account, File dir, int index) =>
      "${toPath(account, dir)}[$index]";

  final String path;
  final int index;
  final List<File> data;
}

class AppDbAlbumEntry {
  static const indexName = "albumStore_path_index";
  static const keyPath = ["path", "index"];
  static const maxDataSize = 160;

  AppDbAlbumEntry(this.path, this.index, this.album);

  JsonObj toJson() {
    return {
      "path": path,
      "index": index,
      "album": album.toAppDbJson(),
    };
  }

  factory AppDbAlbumEntry.fromJson(JsonObj json, Account account) {
    return AppDbAlbumEntry(
      json["path"],
      json["index"],
      Album.fromJson(
        json["album"].cast<String, dynamic>(),
        upgraderFactory: DefaultAlbumUpgraderFactory(
          account: account,
          logFilePath: json["path"],
        ),
      )!,
    );
  }

  static String toPath(Account account, String filePath) =>
      "${account.url}/$filePath";
  static String toPathFromFile(Account account, File albumFile) =>
      toPath(account, albumFile.path);
  static String toPrimaryKey(Account account, File albumFile, int index) =>
      "${toPathFromFile(account, albumFile)}[$index]";

  final String path;
  final int index;
  // properties other than Album.items is undefined when index > 0
  final Album album;
}

class AppDbFileDbEntry {
  static const indexName = "fileDbStore_namespacedFileId";
  static const keyPath = "namespacedFileId";

  AppDbFileDbEntry(this.namespacedFileId, this.file);

  factory AppDbFileDbEntry.fromFile(Account account, File file) {
    return AppDbFileDbEntry(toNamespacedFileId(account, file.fileId!), file);
  }

  JsonObj toJson() {
    return {
      "namespacedFileId": namespacedFileId,
      "file": file.toJson(),
    };
  }

  factory AppDbFileDbEntry.fromJson(JsonObj json) {
    return AppDbFileDbEntry(
      json["namespacedFileId"],
      File.fromJson(json["file"].cast<String, dynamic>()),
    );
  }

  /// File ID namespaced by the server URL
  final String namespacedFileId;
  final File file;

  static String toPrimaryKey(Account account, File file) =>
      "${account.url}/${file.path}";

  static String toNamespacedFileId(Account account, int fileId) =>
      "${account.url}/$fileId";
}
