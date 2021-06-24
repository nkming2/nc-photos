import 'dart:async';

import 'package:idb_shim/idb.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:synchronized/synchronized.dart';

class AppDb {
  static const dbName = "app.db";
  static const dbVersion = 3;
  static const fileStoreName = "files";
  static const albumStoreName = "albums";

  /// this is a stupid name but 'files' is already being used so...
  static const fileDbStoreName = "filesDb";

  /// Run [fn] with an opened database instance
  ///
  /// This function guarantees that:
  /// 1) Database is always closed after [fn] exits, even with an error
  /// 2) Only at most 1 database instance being opened at any time
  static Future<T> use<T>(FutureOr<T> Function(Database) fn) async {
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
  static Future<Database> _open() async {
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

  static final _log = Logger("app_db.AppDb");
  static final _lock = Lock(reentrant: true);
}

class AppDbFileEntry {
  static const indexName = "fileStore_path_index";
  static const keyPath = ["path", "index"];
  static const maxDataSize = 160;

  AppDbFileEntry(this.path, this.index, this.data);

  Map<String, dynamic> toJson() {
    return {
      "path": path,
      "index": index,
      "data": data.map((e) => e.toJson()).toList(),
    };
  }

  factory AppDbFileEntry.fromJson(Map<String, dynamic> json) {
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

  Map<String, dynamic> toJson() {
    return {
      "path": path,
      "index": index,
      "album": album.toAppDbJson(),
    };
  }

  factory AppDbAlbumEntry.fromJson(Map<String, dynamic> json) {
    return AppDbAlbumEntry(
      json["path"],
      json["index"],
      Album.fromJson(
        json["album"].cast<String, dynamic>(),
        upgraderV1: AlbumUpgraderV1(),
      ),
    );
  }

  static String toRootPath(Account account) =>
      "${account.url}/${remote_storage_util.getRemoteAlbumsDir(account)}";
  static String toPath(Account account, File albumFile) =>
      "${account.url}/${albumFile.path}";
  static String toPrimaryKey(Account account, File albumFile, int index) =>
      "${toPath(account, albumFile)}[$index]";

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
    return AppDbFileDbEntry(toNamespacedFileId(account, file), file);
  }

  Map<String, dynamic> toJson() {
    return {
      "namespacedFileId": namespacedFileId,
      "file": file.toJson(),
    };
  }

  factory AppDbFileDbEntry.fromJson(Map<String, dynamic> json) {
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

  static String toNamespacedFileId(Account account, File file) =>
      "${account.url}/${file.fileId}";
}
