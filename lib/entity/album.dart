import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/int_util.dart' as int_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:nc_photos/use_case/put_file_binary.dart';
import 'package:path/path.dart' as path;
import 'package:quiver/iterables.dart';
import 'package:tuple/tuple.dart';

bool isAlbumFile(File file) =>
    path.dirname(file.path).endsWith(".com.nkming.nc_photos/albums");

List<AlbumItem> makeDistinctAlbumItems(List<AlbumItem> items) =>
    items.distinctIf(
        (a, b) =>
            a is AlbumFileItem &&
            b is AlbumFileItem &&
            a.file.path == b.file.path, (a) {
      if (a is AlbumFileItem) {
        return a.file.path.hashCode;
      } else {
        return Random().nextInt(0xFFFFFFFF);
      }
    });

abstract class AlbumItem {
  AlbumItem();

  factory AlbumItem.fromJson(Map<String, dynamic> json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumFileItem._type:
        return AlbumFileItem.fromJson(content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  Map<String, dynamic> toJson() {
    String getType() {
      if (this is AlbumFileItem) {
        return AlbumFileItem._type;
      } else {
        throw StateError("Unknwon subtype");
      }
    }

    return {
      "type": getType(),
      "content": toContentJson(),
    };
  }

  Map<String, dynamic> toContentJson();

  static final _log = Logger("entity.album.AlbumItem");
}

class AlbumFileItem extends AlbumItem with EquatableMixin {
  AlbumFileItem({this.file});

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => equals(other, isDeep: true);

  bool equals(Object other, {bool isDeep = false}) {
    if (other is AlbumFileItem) {
      return super == other &&
          (file == null) == (other.file == null) &&
          (file?.equals(other.file, isDeep: isDeep) ?? true);
    } else {
      return false;
    }
  }

  factory AlbumFileItem.fromJson(Map<String, dynamic> json) {
    return AlbumFileItem(
      file: File.fromJson(json["file"].cast<String, dynamic>()),
    );
  }

  @override
  toString() {
    return "$runtimeType {"
        "file: $file"
        "}";
  }

  @override
  toContentJson() {
    return {
      "file": file.toJson(),
    };
  }

  @override
  get props => [
        // file is handled separately, see [equals]
      ];

  final File file;

  static const _type = "file";
}

/// Immutable object that represents an album
class Album with EquatableMixin {
  Album({
    DateTime lastUpdated,
    @required String name,
    @required List<AlbumItem> items,
    this.albumFile,
  })  : this.lastUpdated = (lastUpdated ?? DateTime.now()).toUtc(),
        this.name = name ?? "",
        this.items = UnmodifiableListView(items);

  factory Album.fromJson(
    Map<String, dynamic> json, {
    AlbumUpgraderV1 upgraderV1,
  }) {
    final jsonVersion = json["version"];
    if (jsonVersion < 2) {
      json = upgraderV1?.call(json);
      if (json == null) {
        _log.info("[fromJson] Version $jsonVersion not compatible");
        return null;
      }
    }
    return Album(
      lastUpdated: json["lastUpdated"] == null
          ? null
          : DateTime.parse(json["lastUpdated"]),
      name: json["name"],
      items: (json["items"] as List)
          .map((e) => AlbumItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      albumFile: json["albumFile"] == null
          ? null
          : File.fromJson(json["albumFile"].cast<String, dynamic>()),
    );
  }

  @override
  toString({bool isDeep = false}) {
    final itemsStr =
        isDeep ? items.toReadableString() : "List {length: ${items.length}}";
    return "$runtimeType {"
        "lastUpdated: $lastUpdated, "
        "name: $name, "
        "items: $itemsStr, "
        "albumFile: $albumFile, "
        "}";
  }

  /// Return a copy with specified field modified
  ///
  /// [lastUpdated] is handled differently where if null, the current time will
  /// be used. In order to keep [lastUpdated], you must explicitly assign it
  /// with value from this
  Album copyWith({
    DateTime lastUpdated,
    String name,
    List<AlbumItem> items,
    File albumFile,
  }) {
    return Album(
      lastUpdated: lastUpdated,
      name: name ?? this.name,
      items: items ?? this.items,
      albumFile: albumFile ?? this.albumFile,
    );
  }

  Map<String, dynamic> toRemoteJson() {
    return {
      "version": version,
      "lastUpdated": lastUpdated.toIso8601String(),
      "name": name,
      "items": items.map((e) => e.toJson()).toList(),
      // ignore albumFile
    };
  }

  Map<String, dynamic> toAppDbJson() {
    return {
      "version": version,
      "lastUpdated": lastUpdated.toIso8601String(),
      "name": name,
      "items": items.map((e) => e.toJson()).toList(),
      if (albumFile != null) "albumFile": albumFile.toJson(),
    };
  }

  @override
  get props => [
        lastUpdated,
        name,
        items,
        albumFile,
      ];

  final DateTime lastUpdated;
  final String name;

  /// Immutable list of items. Modifying the list will result in an error
  final List<AlbumItem> items;

  /// How is this album stored on server
  ///
  /// This field is typically only meaningful when returned by [AlbumRepo.get]
  final File albumFile;

  /// versioning of this class, use to upgrade old persisted album
  static const version = 2;
}

class AlbumRepo {
  AlbumRepo(this.dataSrc);

  /// See [AlbumDataSource.get]
  Future<Album> get(Account account, File albumFile) =>
      this.dataSrc.get(account, albumFile);

  /// See [AlbumDataSource.create]
  Future<Album> create(Account account, Album album) =>
      this.dataSrc.create(account, album);

  /// See [AlbumDataSource.update]
  Future<void> update(Account account, Album album) =>
      this.dataSrc.update(account, album);

  /// See [AlbumDataSource.cleanUp]
  Future<void> cleanUp(Account account, List<File> albumFiles) =>
      this.dataSrc.cleanUp(account, albumFiles);

  final AlbumDataSource dataSrc;
}

abstract class AlbumDataSource {
  /// Return the album defined by [albumFile]
  Future<Album> get(Account account, File albumFile);

  // Create a new album
  Future<Album> create(Account account, Album album);

  /// Update an album
  Future<void> update(Account account, Album album);

  /// Clean up cached albums
  ///
  /// Remove dangling albums in cache not listed in [albumFiles]. Do nothing if
  /// this data source does not cache previous results
  Future<void> cleanUp(Account account, List<File> albumFiles);
}

class AlbumRemoteDataSource implements AlbumDataSource {
  @override
  get(Account account, File albumFile) async {
    _log.info("[get] ${albumFile.path}");
    final fileRepo = FileRepo(FileWebdavDataSource());
    final data = await GetFileBinary(fileRepo)(account, albumFile);
    try {
      return Album.fromJson(
        jsonDecode(utf8.decode(data)),
        upgraderV1: AlbumUpgraderV1(),
      ).copyWith(albumFile: albumFile);
    } catch (e, stacktrace) {
      dynamic d = data;
      try {
        d = utf8.decode(data);
      } catch (_) {}
      _log.severe("[get] Invalid json data: $d", e, stacktrace);
      throw FormatException("Invalid album format");
    }
  }

  @override
  create(Account account, Album album) async {
    _log.info("[create]");
    final fileName = _makeAlbumFileName();
    final filePath =
        "${remote_storage_util.getRemoteAlbumsDir(account)}/$fileName";
    final fileRepo = FileRepo(FileWebdavDataSource());
    await PutFileBinary(fileRepo)(
        account, filePath, utf8.encode(jsonEncode(album.toRemoteJson())),
        shouldCreateMissingDir: true);
    // query album file
    final list = await Ls(fileRepo)(account, File(path: filePath),
        shouldExcludeRootDir: false);
    return album.copyWith(albumFile: list.first);
  }

  @override
  update(Account account, Album album) async {
    _log.info("[update] ${album.albumFile.path}");
    final fileRepo = FileRepo(FileWebdavDataSource());
    await PutFileBinary(fileRepo)(account, album.albumFile.path,
        utf8.encode(jsonEncode(album.toRemoteJson())));
  }

  @override
  cleanUp(Account account, List<File> albumFiles) async {}

  String _makeAlbumFileName() {
    // just make up something
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(0xFFFFFF);
    return "${timestamp.toRadixString(16)}-${random.toRadixString(16).padLeft(6, '0')}.json";
  }

  static final _log = Logger("entity.album.AlbumRemoteDataSource");
}

class AlbumAppDbDataSource implements AlbumDataSource {
  @override
  get(Account account, File albumFile) {
    _log.info("[get] ${albumFile.path}");
    return AppDb.use((db) async {
      final transaction = db.transaction(AppDb.albumStoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.albumStoreName);
      final index = store.index(AppDbAlbumEntry.indexName);
      final path = AppDbAlbumEntry.toPath(account, albumFile);
      final range = KeyRange.bound([path, 0], [path, int_util.int32Max]);
      final List results = await index.getAll(range);
      if (results?.isNotEmpty == true) {
        final entries = results
            .map((e) => AppDbAlbumEntry.fromJson(e.cast<String, dynamic>()));
        final items = entries.map((e) {
          _log.info("[get] ${e.path}[${e.index}]");
          return e.album.items;
        }).reduce((value, element) => value + element);
        return entries.first.album.copyWith(items: items);
      } else {
        throw CacheNotFoundException("No entry: $path");
      }
    });
  }

  @override
  create(Account account, Album album) async {
    _log.info("[create]");
    throw UnimplementedError();
  }

  @override
  update(Account account, Album album) {
    _log.info("[update] ${album.albumFile.path}");
    return AppDb.use((db) async {
      final transaction =
          db.transaction(AppDb.albumStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.albumStoreName);
      await _cacheAlbum(store, account, album);
    });
  }

  @override
  cleanUp(Account account, List<File> albumFiles) async {}

  static final _log = Logger("entity.album.AlbumAppDbDataSource");
}

class AlbumCachedDataSource implements AlbumDataSource {
  @override
  get(Account account, File albumFile) async {
    try {
      final cache = await _appDbSrc.get(account, albumFile);
      if (cache.albumFile.etag?.isNotEmpty == true &&
          cache.albumFile.etag == albumFile.etag) {
        // cache is good
        _log.fine(
            "[get] etag matched for ${AppDbAlbumEntry.toPath(account, albumFile)}");
        return cache;
      }
      _log.info(
          "[get] Remote content updated for ${AppDbAlbumEntry.toPath(account, albumFile)}");
    } on CacheNotFoundException catch (_) {
      // normal when there's no cache
    } catch (e, stacktrace) {
      _log.shout("[get] Cache failure", e, stacktrace);
    }

    // no cache
    final remote = await _remoteSrc.get(account, albumFile);
    await _cacheResult(account, remote);
    return remote;
  }

  @override
  update(Account account, Album album) async {
    await _remoteSrc.update(account, album);
    await _appDbSrc.update(account, album);
  }

  @override
  create(Account account, Album album) => _remoteSrc.create(account, album);

  @override
  cleanUp(Account account, List<File> albumFiles) async {
    AppDb.use((db) async {
      final transaction =
          db.transaction(AppDb.albumStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.albumStoreName);
      final index = store.index(AppDbAlbumEntry.indexName);
      final rootPath = AppDbAlbumEntry.toRootPath(account);
      final range = KeyRange.bound(
          ["$rootPath/", 0], ["$rootPath/\uffff", int_util.int32Max]);
      final danglingKeys = await index
          // get all albums for this account
          .openKeyCursor(range: range, autoAdvance: true)
          .map((cursor) => Tuple2((cursor.key as List)[0], cursor.primaryKey))
          // and pick the dangling ones
          .where((pair) => !albumFiles
              .any((f) => pair.item1 == AppDbAlbumEntry.toPath(account, f)))
          // map to primary keys
          .map((pair) => pair.item2)
          .toList();
      for (final k in danglingKeys) {
        _log.fine("[cleanUp] Removing DB entry: $k");
        await store.delete(k);
      }
    });
  }

  Future<void> _cacheResult(Account account, Album result) {
    return AppDb.use((db) async {
      final transaction =
          db.transaction(AppDb.albumStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.albumStoreName);
      await _cacheAlbum(store, account, result);
    });
  }

  final _remoteSrc = AlbumRemoteDataSource();
  final _appDbSrc = AlbumAppDbDataSource();

  static final _log = Logger("entity.album.AlbumCachedDataSource");
}

Future<void> _cacheAlbum(
    ObjectStore store, Account account, Album album) async {
  final index = store.index(AppDbAlbumEntry.indexName);
  final path = AppDbAlbumEntry.toPath(account, album.albumFile);
  final range = KeyRange.bound([path, 0], [path, int_util.int32Max]);
  // count number of entries for this album
  final count = await index.count(range);
  int newCount = 0;

  var albumItemLists =
      partition(album.items, AppDbAlbumEntry.maxDataSize).toList();
  if (albumItemLists.isEmpty) {
    albumItemLists = [<AlbumItem>[]];
  }

  for (final pair in albumItemLists.withIndex()) {
    _log.info(
        "[_cacheAlbum] Caching $path[${pair.item1}], length: ${pair.item2.length}");
    await store.put(
      AppDbAlbumEntry(path, pair.item1, album.copyWith(items: pair.item2))
          .toJson(),
      AppDbAlbumEntry.toPrimaryKey(account, album.albumFile, pair.item1),
    );
    ++newCount;
  }
  if (count > newCount) {
    // index is 0-based
    final rmRange = KeyRange.bound([path, newCount], [path, int_util.int32Max]);
    final rmKeys = await index
        .openKeyCursor(range: rmRange, autoAdvance: true)
        .map((cursor) => cursor.primaryKey)
        .toList();
    for (final k in rmKeys) {
      _log.fine("[_cacheAlbum] Removing DB entry: $k");
      await store.delete(k);
    }
  }
}

final _log = Logger("entity.album");
