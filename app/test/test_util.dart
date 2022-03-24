import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/type.dart';

class FilesBuilder {
  FilesBuilder({
    int initialFileId = 0,
  }) : fileId = initialFileId;

  List<File> build() {
    return files.map((f) => f.copyWith()).toList();
  }

  void add(
    String relativePath, {
    int? contentLength,
    String? contentType,
    DateTime? lastModified,
    bool isCollection = false,
    bool hasPreview = true,
    String ownerId = "admin",
  }) {
    files.add(File(
      path: "remote.php/dav/files/$relativePath",
      contentLength: contentLength,
      contentType: contentType,
      lastModified:
          lastModified ?? DateTime.utc(2020, 1, 2, 3, 4, 5 + files.length),
      isCollection: isCollection,
      hasPreview: hasPreview,
      fileId: fileId++,
      ownerId: ownerId.toCi(),
    ));
  }

  void addGenericFile(
    String relativePath,
    String contentType, {
    int contentLength = 1024,
    DateTime? lastModified,
    bool hasPreview = true,
    String ownerId = "admin",
  }) =>
      add(
        relativePath,
        contentLength: contentLength,
        contentType: contentType,
        lastModified: lastModified,
        hasPreview: hasPreview,
        ownerId: ownerId,
      );

  void addJpeg(
    String relativePath, {
    int contentLength = 1024,
    DateTime? lastModified,
    bool hasPreview = true,
    String ownerId = "admin",
  }) =>
      add(
        relativePath,
        contentLength: contentLength,
        contentType: "image/jpeg",
        lastModified: lastModified,
        hasPreview: hasPreview,
        ownerId: ownerId,
      );

  void addDir(
    String relativePath, {
    int contentLength = 1024,
    DateTime? lastModified,
    String ownerId = "admin",
  }) =>
      add(
        relativePath,
        lastModified: lastModified,
        isCollection: true,
        hasPreview: false,
        ownerId: ownerId,
      );

  final files = <File>[];
  int fileId;
}

/// Create an album for testing
class AlbumBuilder {
  AlbumBuilder({
    DateTime? lastUpdated,
    String? name,
    this.albumFilename = "test0.nc_album.json",
    this.fileId = 0,
    String? ownerId,
  })  : lastUpdated = lastUpdated ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
        name = name ?? "test",
        ownerId = ownerId ?? "admin";

  factory AlbumBuilder.ofId({
    required int albumId,
    DateTime? lastUpdated,
    String? name,
    String? ownerId,
  }) =>
      AlbumBuilder(
        lastUpdated: lastUpdated,
        name: name,
        albumFilename: "test$albumId.nc_album.json",
        fileId: albumId,
        ownerId: ownerId,
      );

  Album build() {
    final latestFileItem = items
        .whereType<AlbumFileItem>()
        .stableSorted(
            (a, b) => a.file.lastModified!.compareTo(b.file.lastModified!))
        .reversed
        .firstOrNull;
    return Album(
      lastUpdated: lastUpdated,
      name: name,
      provider: AlbumStaticProvider(
        items: items,
        latestItemTime: latestFileItem?.file.lastModified,
      ),
      coverProvider: cover == null
          ? AlbumAutoCoverProvider(coverFile: latestFileItem?.file)
          : AlbumManualCoverProvider(coverFile: cover!),
      sortProvider: const AlbumNullSortProvider(),
      shares: shares.isEmpty ? null : shares,
      albumFile: buildAlbumFile(
        path: buildAlbumFilePath(albumFilename, user: ownerId),
        fileId: fileId,
        ownerId: ownerId,
      ),
    );
  }

  /// Add a file item
  ///
  /// By default, the item will be added by admin and added at the same time as
  /// the file's lastModified.
  ///
  /// If [isCover] is true, the coverProvider of the album will become
  /// [AlbumManualCoverProvider]
  void addFileItem(
    File file, {
    String addedBy = "admin",
    DateTime? addedAt,
    bool isCover = false,
  }) {
    final fileItem = AlbumFileItem(
      file: file,
      addedBy: addedBy.toCi(),
      addedAt: addedAt ?? file.lastModified!,
    );
    items.add(fileItem);
    if (isCover) {
      cover = file;
    }
  }

  /// Add an album share
  ///
  /// By default, the album will be shared at 2020-01-02 03:04:05
  void addShare(
    String userId, {
    DateTime? sharedAt,
  }) {
    shares.add(buildAlbumShare(
      userId: userId,
      sharedAt: sharedAt,
    ));
  }

  static List<AlbumFileItem> fileItemsOf(Album album) =>
      AlbumStaticProvider.of(album).items.whereType<AlbumFileItem>().toList();

  final DateTime lastUpdated;
  final String name;
  final String albumFilename;
  final int fileId;
  final String ownerId;

  final items = <AlbumItem>[];
  File? cover;
  final shares = <AlbumShare>[];
}

void initLog() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    String msg =
        "[${record.loggerName}] ${record.level.name}: ${record.message}";
    if (record.error != null) {
      msg += " (throw: ${record.error.runtimeType} { ${record.error} })";
    }
    if (record.stackTrace != null) {
      msg += "\nStack Trace:\n${record.stackTrace}";
    }

    int color;
    if (record.level >= Level.SEVERE) {
      color = 91;
    } else if (record.level >= Level.WARNING) {
      color = 33;
    } else if (record.level >= Level.INFO) {
      color = 34;
    } else if (record.level >= Level.FINER) {
      color = 32;
    } else {
      color = 90;
    }
    msg = "\x1B[${color}m$msg\x1B[0m";

    debugPrint(msg);
  });
}

Account buildAccount({
  String id = "123456-000000",
  String scheme = "http",
  String address = "example.com",
  String username = "admin",
  String password = "pass",
  List<String> roots = const [""],
}) =>
    Account(id, scheme, address, username.toCi(), password, null, roots);

/// Build a mock [File] pointing to a album JSON file
///
/// Warning: not all fields are filled, but the most essential ones are
File buildAlbumFile({
  required String path,
  int contentLength = 1024,
  DateTime? lastModified,
  required int fileId,
  String ownerId = "admin",
}) =>
    File(
      path: path,
      contentLength: contentLength,
      contentType: "application/json",
      lastModified: lastModified ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
      isCollection: false,
      hasPreview: false,
      fileId: fileId,
      ownerId: ownerId.toCi(),
    );

String buildAlbumFilePath(
  String filename, {
  String user = "admin",
}) =>
    "remote.php/dav/files/$user/.com.nkming.nc_photos/albums/$filename";

AlbumShare buildAlbumShare({
  required String userId,
  String? displayName,
  DateTime? sharedAt,
}) =>
    AlbumShare(
      userId: userId.toCi(),
      displayName: displayName ?? userId,
      sharedAt: sharedAt ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
    );

/// Build a mock [File] pointing to a JPEG image file
///
/// Warning: not all fields are filled, but the most essential ones are
File buildJpegFile({
  required String path,
  int contentLength = 1024,
  DateTime? lastModified,
  bool hasPreview = true,
  required int fileId,
  String ownerId = "admin",
}) =>
    File(
      path: path,
      contentLength: contentLength,
      contentType: "image/jpeg",
      lastModified: lastModified ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
      isCollection: false,
      hasPreview: hasPreview,
      fileId: fileId,
      ownerId: ownerId.toCi(),
    );

Share buildShare({
  required String id,
  DateTime? stime,
  String uidOwner = "admin",
  String? displaynameOwner,
  required File file,
  required String shareWith,
}) =>
    Share(
      id: id,
      shareType: ShareType.user,
      stime: stime ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
      uidOwner: uidOwner.toCi(),
      displaynameOwner: displaynameOwner ?? uidOwner,
      uidFileOwner: file.ownerId!,
      path: file.strippedPath,
      itemType: ShareItemType.file,
      mimeType: file.contentType ?? "",
      itemSource: file.fileId!,
      shareWith: shareWith.toCi(),
      shareWithDisplayName: shareWith,
    );

Sharee buildSharee({
  ShareeType type = ShareeType.user,
  String? label,
  int shareType = 0,
  required CiString shareWith,
  String? shareWithDisplayNameUnique,
}) =>
    Sharee(
      type: type,
      label: label ?? shareWith.toString(),
      shareType: shareType,
      shareWith: shareWith,
    );

Future<void> fillAppDb(
    AppDb appDb, Account account, Iterable<File> files) async {
  await appDb.use(
    (db) => db.transaction(AppDb.file2StoreName, idbModeReadWrite),
    (transaction) async {
      final file2Store = transaction.objectStore(AppDb.file2StoreName);
      for (final f in files) {
        await file2Store.put(AppDbFile2Entry.fromFile(account, f).toJson(),
            AppDbFile2Entry.toPrimaryKeyForFile(account, f));
      }
    },
  );
}

Future<void> fillAppDbDir(
    AppDb appDb, Account account, File dir, List<File> children) async {
  await appDb.use(
    (db) => db.transaction(AppDb.dirStoreName, idbModeReadWrite),
    (transaction) async {
      final dirStore = transaction.objectStore(AppDb.dirStoreName);
      await dirStore.put(
          AppDbDirEntry.fromFiles(account, dir, children).toJson(),
          AppDbDirEntry.toPrimaryKeyForDir(account, dir));
    },
  );
}

Future<List<T>> listAppDb<T>(
    AppDb appDb, String storeName, T Function(JsonObj) transform) {
  return appDb.use(
    (db) => db.transaction(storeName, idbModeReadOnly),
    (transaction) async {
      final store = transaction.objectStore(storeName);
      return await store
          .openCursor(autoAdvance: true)
          .map((c) => c.value)
          .cast<Map>()
          .map((e) => transform(e.cast<String, dynamic>()))
          .toList();
    },
  );
}
