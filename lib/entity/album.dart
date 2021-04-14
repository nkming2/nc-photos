import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:nc_photos/use_case/put_file_binary.dart';
import 'package:path/path.dart' as path;

String getAlbumFileRoot(Account account) =>
    "${api_util.getWebdavRootUrlRelative(account)}/.com.nkming.nc_photos";

bool isAlbumFile(File file) =>
    path.basename(path.dirname(file.path)) == ".com.nkming.nc_photos";

abstract class AlbumItem {
  AlbumItem();

  factory AlbumItem.fromJson(Map<String, dynamic> json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumFileItem._type:
        return AlbumFileItem.fromJson(content.cast<String, dynamic>());
      default:
        _log.severe("[fromJson] Unknown type: $type");
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

class AlbumFileItem extends AlbumItem {
  AlbumFileItem({this.file});

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

  final File file;

  static const _type = "file";
}

/// Immutable object that represents an album
class Album {
  Album({
    DateTime lastUpdated,
    @required String name,
    @required List<AlbumItem> items,
    this.albumFile,
  })  : this.lastUpdated = (lastUpdated ?? DateTime.now()).toUtc(),
        this.name = name ?? "",
        this.items = UnmodifiableListView(items);

  factory Album.versioned({
    int version,
    DateTime lastUpdated,
    @required String name,
    @required List<AlbumItem> items,
    File albumFile,
  }) {
    // there's only one version right now
    if (version < 2) {
      return Album(
        lastUpdated: lastUpdated,
        name: name,
        items: [],
        albumFile: albumFile,
      );
    } else {
      return Album(
        lastUpdated: lastUpdated,
        name: name,
        items: items,
        albumFile: albumFile,
      );
    }
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album.versioned(
      version: json["version"],
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
  toString() {
    return "$runtimeType {"
        "lastUpdated: $lastUpdated, "
        "name: $name, "
        "items: ${items.toReadableString()}, "
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

  Map<String, dynamic> _toRemoteJson() {
    return {
      "version": version,
      "lastUpdated": lastUpdated.toIso8601String(),
      "name": name,
      "items": items.map((e) => e.toJson()).toList(),
      // ignore albumFile
    };
  }

  Map<String, dynamic> _toAppDbJson() {
    return {
      "version": version,
      "lastUpdated": lastUpdated.toIso8601String(),
      "name": name,
      "items": items.map((e) => e.toJson()).toList(),
      if (albumFile != null) "albumFile": albumFile.toJson(),
    };
  }

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
      return Album.fromJson(jsonDecode(utf8.decode(data)))
          .copyWith(albumFile: albumFile);
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
    final filePath = "${getAlbumFileRoot(account)}/$fileName";
    final fileRepo = FileRepo(FileWebdavDataSource());
    try {
      await PutFileBinary(fileRepo)(
          account, filePath, utf8.encode(jsonEncode(album._toRemoteJson())));
    } on ApiException catch (e) {
      if (e.response.statusCode == 404) {
        _log.info("[create] Missing album dir, creating");
        // no dir
        await _createDir(account);
        // then retry
        await PutFileBinary(fileRepo)(
            account, filePath, utf8.encode(jsonEncode(album._toRemoteJson())));
      } else {
        rethrow;
      }
    }
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
        utf8.encode(jsonEncode(album._toRemoteJson())));
  }

  @override
  cleanUp(Account account, List<File> albumFiles) async {}

  String _makeAlbumFileName() {
    // just make up something
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(0xFFFFFF);
    return "${timestamp.toRadixString(16)}-${random.toRadixString(16).padLeft(6, '0')}.json";
  }

  Future<void> _createDir(Account account) {
    return Api(account).files().mkcol(path: getAlbumFileRoot(account));
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
      final Map result =
          await store.getObject("${_getCacheKey(account, albumFile)}");
      if (result != null) {
        return Album.fromJson(result.cast<String, dynamic>());
      } else {
        throw CacheNotFoundException(
            "No entry: ${_getCacheKey(account, albumFile)}");
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
      await store.put(
          album._toAppDbJson(), _getCacheKey(account, album.albumFile));
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
        _log.fine("[get] etag matched for ${_getCacheKey(account, albumFile)}");
        return cache;
      } else {
        _log.info(
            "[get] Remote content updated for ${_getCacheKey(account, albumFile)}");
      }
    } catch (e, stacktrace) {
      // no cache
      if (e is! CacheNotFoundException) {
        _log.severe("[get] Cache failure", e, stacktrace);
      }
    }

    // no cache
    final remote = await _remoteSrc.get(account, albumFile);
    await _cacheResult(account, albumFile, remote);
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
      final keyPrefix = _getCacheKeyPrefix(account);
      final range = KeyRange.bound("$keyPrefix/", "$keyPrefix/\uffff");
      final danglingKeys = await store
          // get all albums for this account
          .openKeyCursor(range: range, autoAdvance: true)
          .map((cursor) => cursor.key)
          // and pick the dangling ones
          .where((key) =>
              !albumFiles.any((f) => key == "${_getCacheKey(account, f)}"))
          .toList();
      for (final k in danglingKeys) {
        _log.fine("[cleanUp] Removing DB entry: $k");
        await store.delete(k);
      }
    });
  }

  Future<void> _cacheResult(Account account, File albumFile, Album result) {
    return AppDb.use((db) async {
      final transaction =
          db.transaction(AppDb.albumStoreName, idbModeReadWrite);
      final store = transaction.objectStore(AppDb.albumStoreName);
      await store.put(result._toAppDbJson(), _getCacheKey(account, albumFile));
    });
  }

  final _remoteSrc = AlbumRemoteDataSource();
  final _appDbSrc = AlbumAppDbDataSource();

  static final _log = Logger("entity.album.AlbumCachedDataSource");
}

String _getCacheKeyPrefix(Account account) => account.url;

String _getCacheKey(Account account, File albumFile) =>
    "${_getCacheKeyPrefix(account)}/${albumFile.path}";
