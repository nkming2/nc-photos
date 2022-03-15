import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:idb_shim/idb.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/num_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/type.dart';
import 'package:synchronized/synchronized.dart';

class AppDb {
  static const dbName = "app.db";
  static const dbVersion = 6;
  static const albumStoreName = "albums";
  static const file2StoreName = "files2";
  static const dirStoreName = "dirs";
  static const metaStoreName = "meta";

  factory AppDb() => _inst;

  AppDb._();

  /// Run [fn] with an opened database instance
  ///
  /// This function guarantees that:
  /// 1) Database is always closed after [fn] exits, even with an error
  /// 2) Only at most 1 database instance being opened at any time
  Future<T> use<T>(FutureOr<T> Function(Database db) fn) async {
    // make sure only one client is opening the db
    return await platform.Lock.synchronized(k.appDbLockId, () async {
      final db = await _open();
      try {
        return await fn(db);
      } finally {
        db.close();
      }
    });
  }

  Future<void> delete() async {
    _log.warning("[delete] Deleting database");
    return await _lock.synchronized(() async {
      final dbFactory = platform.getDbFactory();
      await dbFactory.deleteDatabase(dbName);
    });
  }

  /// Open the database
  Future<Database> _open() {
    if (platform_k.isWeb) {
      return _openNative();
    } else {
      return _openSqflite();
    }
  }

  /// Open the sqflite database
  ///
  /// We can't simply call deleteObjectStore on upgrade failure here, as the
  /// package does not remove the corresponding indexes, so when we recreate
  /// the indexes later, it'll fail. What we do here, is to delete the whole
  /// database instead
  Future<Database> _openSqflite() async {
    final dbFactory = platform.getDbFactory();
    try {
      int? fromVersion, toVersion;
      final db = await dbFactory.open(
        dbName,
        version: dbVersion,
        onUpgradeNeeded: (event) {
          _upgrade(event);
          fromVersion = event.oldVersion;
          toVersion = event.newVersion;
        },
      );
      if (fromVersion != null && toVersion != null) {
        await _onPostUpgrade(db, fromVersion!, toVersion!);
      }
      return db;
    } catch (e, stackTrace) {
      _log.shout(
          "[_openSqflite] Failed while upgrading database", e, stackTrace);
      _log.warning("[_openSqflite] Recreating db");
      await dbFactory.deleteDatabase(dbName);
      return dbFactory.open(dbName,
          version: dbVersion, onUpgradeNeeded: _upgrade);
    }
  }

  /// Open the native IndexedDB database
  ///
  /// Errors thrown in onUpgradeNeeded are not propagated properly to us on web,
  /// so the sqflite approach will not work
  Future<Database> _openNative() async {
    final dbFactory = platform.getDbFactory();
    int? fromVersion, toVersion;
    final db = await dbFactory.open(
      dbName,
      version: dbVersion,
      onUpgradeNeeded: (event) {
        try {
          _upgrade(event);
          fromVersion = event.oldVersion;
          toVersion = event.newVersion;
        } catch (e, stackTrace) {
          _log.shout(
              "[_openNative] Failed while upgrading database", e, stackTrace);
          // drop the db and rebuild a new one instead
          try {
            event.database.deleteObjectStore(albumStoreName);
          } catch (_) {}
          try {
            event.database.deleteObjectStore(file2StoreName);
          } catch (_) {}
          try {
            event.database.deleteObjectStore(dirStoreName);
          } catch (_) {}
          try {
            event.database.deleteObjectStore(metaStoreName);
          } catch (_) {}
          try {
            event.database.deleteObjectStore(_fileDbStoreName);
          } catch (_) {}
          try {
            event.database.deleteObjectStore(_fileStoreName);
          } catch (_) {}
          _log.warning("[_openNative] Recreating db");
          _upgrade(_DummyVersionChangeEvent(
              0,
              event.newVersion,
              event.transaction,
              event.target,
              event.currentTarget,
              event.database));
        }
      },
    );
    if (fromVersion != null && toVersion != null) {
      await _onPostUpgrade(db, fromVersion!, toVersion!);
    }
    return db;
  }

  void _upgrade(VersionChangeEvent event) {
    _log.info("[_upgrade] Upgrade database: ${event.oldVersion} -> $dbVersion");

    final db = event.database;
    // ignore: unused_local_variable
    ObjectStore? albumStore, file2Store, dirStore, metaStore;
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
      // no longer relevant in v4

      // recreate file store from scratch
      // no longer relevant in v4
    }
    if (event.oldVersion < 4) {
      try {
        db.deleteObjectStore(_fileDbStoreName);
      } catch (_) {}
      try {
        db.deleteObjectStore(_fileStoreName);
      } catch (_) {}

      file2Store = db.createObjectStore(file2StoreName);
      file2Store.createIndex(AppDbFile2Entry.strippedPathIndexName,
          AppDbFile2Entry.strippedPathKeyPath);

      dirStore = db.createObjectStore(dirStoreName);
    }
    file2Store ??= event.transaction.objectStore(file2StoreName);
    if (event.oldVersion < 5) {
      file2Store.createIndex(AppDbFile2Entry.dateTimeEpochMsIndexName,
          AppDbFile2Entry.dateTimeEpochMsKeyPath);

      metaStore =
          db.createObjectStore(metaStoreName, keyPath: AppDbMetaEntry.keyPath);
    }
    if (event.oldVersion < 6) {
      file2Store.createIndex(AppDbFile2Entry.fileIsFavoriteIndexName,
          AppDbFile2Entry.fileIsFavoriteKeyPath);
    }
  }

  Future<void> _onPostUpgrade(
      Database db, int fromVersion, int toVersion) async {
    if (fromVersion.inRange(1, 4) && toVersion >= 5) {
      final transaction = db.transaction(AppDb.metaStoreName, idbModeReadWrite);
      final metaStore = transaction.objectStore(AppDb.metaStoreName);
      await metaStore
          .put(const AppDbMetaEntryDbCompatV5(false).toEntry().toJson());
      await transaction.completed;
    }
  }

  static late final _inst = AppDb._();
  final _lock = Lock(reentrant: true);

  static const _fileDbStoreName = "filesDb";
  static const _fileStoreName = "files";

  static final _log = Logger("app_db.AppDb");
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

class AppDbFile2Entry with EquatableMixin {
  static const strippedPathIndexName = "server_userId_strippedPath";
  static const strippedPathKeyPath = ["server", "userId", "strippedPath"];

  static const dateTimeEpochMsIndexName = "server_userId_dateTimeEpochMs";
  static const dateTimeEpochMsKeyPath = ["server", "userId", "dateTimeEpochMs"];

  static const fileIsFavoriteIndexName = "server_userId_fileIsFavorite";
  static const fileIsFavoriteKeyPath = ["server", "userId", "file.isFavorite"];

  AppDbFile2Entry(this.server, this.userId, this.strippedPath,
      this.dateTimeEpochMs, this.file);

  factory AppDbFile2Entry.fromFile(Account account, File file) =>
      AppDbFile2Entry(account.url, account.username, file.strippedPathWithEmpty,
          file.bestDateTime.millisecondsSinceEpoch, file);

  factory AppDbFile2Entry.fromJson(JsonObj json) => AppDbFile2Entry(
        json["server"],
        (json["userId"] as String).toCi(),
        json["strippedPath"],
        json["dateTimeEpochMs"],
        File.fromJson(json["file"].cast<String, dynamic>()),
      );

  JsonObj toJson() => {
        "server": server,
        "userId": userId.toCaseInsensitiveString(),
        "strippedPath": strippedPath,
        "dateTimeEpochMs": dateTimeEpochMs,
        "file": file.toJson(),
      };

  static String toPrimaryKey(Account account, int fileId) =>
      "${account.url}/${account.username.toCaseInsensitiveString()}/$fileId";

  static String toPrimaryKeyForFile(Account account, File file) =>
      toPrimaryKey(account, file.fileId!);

  static List<Object> toStrippedPathIndexKey(
          Account account, String strippedPath) =>
      [
        account.url,
        account.username.toCaseInsensitiveString(),
        strippedPath == "." ? "" : strippedPath
      ];

  static List<Object> toStrippedPathIndexKeyForFile(
          Account account, File file) =>
      toStrippedPathIndexKey(account, file.strippedPathWithEmpty);

  /// Return the lower bound key used to query files under [dir] and its sub
  /// dirs
  static List<Object> toStrippedPathIndexLowerKeyForDir(
          Account account, File dir) =>
      [
        account.url,
        account.username.toCaseInsensitiveString(),
        dir.strippedPath.run((p) => p == "." ? "" : "$p/")
      ];

  /// Return the upper bound key used to query files under [dir] and its sub
  /// dirs
  static List<Object> toStrippedPathIndexUpperKeyForDir(
      Account account, File dir) {
    return toStrippedPathIndexLowerKeyForDir(account, dir).run((k) {
      k[2] = (k[2] as String) + "\uffff";
      return k;
    });
  }

  static List<Object> toDateTimeEpochMsIndexKey(Account account, int epochMs) =>
      [
        account.url,
        account.username.toCaseInsensitiveString(),
        epochMs,
      ];

  static List<Object> toFileIsFavoriteIndexKey(
          Account account, bool isFavorite) =>
      [
        account.url,
        account.username.toCaseInsensitiveString(),
        isFavorite ? 1 : 0,
      ];

  @override
  get props => [
        server,
        userId,
        strippedPath,
        dateTimeEpochMs,
        file,
      ];

  /// Server URL where this file belongs to
  final String server;
  final CiString userId;
  final String strippedPath;
  final int dateTimeEpochMs;
  final File file;
}

class AppDbDirEntry with EquatableMixin {
  AppDbDirEntry._(
      this.server, this.userId, this.strippedPath, this.dir, this.children);

  factory AppDbDirEntry.fromFiles(
          Account account, File dir, List<File> children) =>
      AppDbDirEntry._(
        account.url,
        account.username,
        dir.strippedPathWithEmpty,
        dir,
        children.map((f) => f.fileId!).toList(),
      );

  factory AppDbDirEntry.fromJson(JsonObj json) => AppDbDirEntry._(
        json["server"],
        (json["userId"] as String).toCi(),
        json["strippedPath"],
        File.fromJson((json["dir"] as Map).cast<String, dynamic>()),
        json["children"].cast<int>(),
      );

  JsonObj toJson() => {
        "server": server,
        "userId": userId.toCaseInsensitiveString(),
        "strippedPath": strippedPath,
        "dir": dir.toJson(),
        "children": children,
      };

  static String toPrimaryKeyForDir(Account account, File dir) =>
      "${account.url}/${account.username.toCaseInsensitiveString()}/${dir.strippedPathWithEmpty}";

  /// Return the lower bound key used to query dirs under [root] and its sub
  /// dirs
  static String toPrimaryLowerKeyForSubDirs(Account account, File root) {
    final strippedPath = root.strippedPath.run((p) => p == "." ? "" : "$p/");
    return "${account.url}/${account.username.toCaseInsensitiveString()}/$strippedPath";
  }

  /// Return the upper bound key used to query dirs under [root] and its sub
  /// dirs
  static String toPrimaryUpperKeyForSubDirs(Account account, File root) =>
      toPrimaryLowerKeyForSubDirs(account, root) + "\uffff";

  @override
  get props => [
        server,
        userId,
        strippedPath,
        dir,
        children,
      ];

  /// Server URL where this file belongs to
  final String server;
  final CiString userId;
  final String strippedPath;
  final File dir;
  final List<int> children;
}

class AppDbMetaEntry with EquatableMixin {
  static const keyPath = "key";

  const AppDbMetaEntry(this.key, this.obj);

  factory AppDbMetaEntry.fromJson(JsonObj json) => AppDbMetaEntry(
        json["key"],
        json["obj"].cast<String, dynamic>(),
      );

  JsonObj toJson() => {
        "key": key,
        "obj": obj,
      };

  @override
  get props => [
        key,
        obj,
      ];

  final String key;
  final JsonObj obj;
}

class AppDbMetaEntryDbCompatV5 {
  static const key = "dbCompatV5";

  const AppDbMetaEntryDbCompatV5(this.isMigrated);

  factory AppDbMetaEntryDbCompatV5.fromJson(JsonObj json) =>
      AppDbMetaEntryDbCompatV5(json["isMigrated"]);

  AppDbMetaEntry toEntry() => AppDbMetaEntry(key, {
        "isMigrated": isMigrated,
      });

  final bool isMigrated;
}

class AppDbMetaEntryCompatV37 {
  static const key = "compatV37";

  const AppDbMetaEntryCompatV37(this.isMigrated);

  factory AppDbMetaEntryCompatV37.fromJson(JsonObj json) =>
      AppDbMetaEntryCompatV37(json["isMigrated"]);

  AppDbMetaEntry toEntry() => AppDbMetaEntry(key, {
        "isMigrated": isMigrated,
      });

  final bool isMigrated;
}

class _DummyVersionChangeEvent implements VersionChangeEvent {
  const _DummyVersionChangeEvent(this.oldVersion, this.newVersion,
      this.transaction, this.target, this.currentTarget, this.database);

  @override
  final int oldVersion;
  @override
  final int newVersion;
  @override
  final Transaction transaction;
  @override
  final Object target;
  @override
  final Object currentTarget;
  @override
  final Database database;
}
