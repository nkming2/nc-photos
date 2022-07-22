import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/object_extension.dart';

class SqliteAlbumConverter {
  static Album fromSql(
      sql.Album album, File albumFile, List<sql.AlbumShare> shares) {
    return Album(
      lastUpdated: album.lastUpdated,
      name: album.name,
      provider: AlbumProvider.fromJson({
        "type": album.providerType,
        "content": jsonDecode(album.providerContent),
      }),
      coverProvider: AlbumCoverProvider.fromJson({
        "type": album.coverProviderType,
        "content": jsonDecode(album.coverProviderContent),
      }),
      sortProvider: AlbumSortProvider.fromJson({
        "type": album.sortProviderType,
        "content": jsonDecode(album.sortProviderContent),
      }),
      shares: shares.isEmpty
          ? null
          : shares
              .map((e) => AlbumShare(
                    userId: e.userId.toCi(),
                    displayName: e.displayName,
                    sharedAt: e.sharedAt.toUtc(),
                  ))
              .toList(),
      albumFile: albumFile,
      savedVersion: album.version,
    );
  }

  static sql.CompleteAlbumCompanion toSql(Album album, int albumFileRowId) {
    final providerJson = album.provider.toJson();
    final coverProviderJson = album.coverProvider.toJson();
    final sortProviderJson = album.sortProvider.toJson();
    final dbAlbum = sql.AlbumsCompanion.insert(
      file: albumFileRowId,
      version: Album.version,
      lastUpdated: album.lastUpdated,
      name: album.name,
      providerType: providerJson["type"],
      providerContent: jsonEncode(providerJson["content"]),
      coverProviderType: coverProviderJson["type"],
      coverProviderContent: jsonEncode(coverProviderJson["content"]),
      sortProviderType: sortProviderJson["type"],
      sortProviderContent: jsonEncode(sortProviderJson["content"]),
    );
    final dbAlbumShares = album.shares
        ?.map((s) => sql.AlbumSharesCompanion(
              userId: Value(s.userId.toCaseInsensitiveString()),
              displayName: Value(s.displayName),
              sharedAt: Value(s.sharedAt),
            ))
        .toList();
    return sql.CompleteAlbumCompanion(dbAlbum, dbAlbumShares ?? []);
  }
}

class SqliteFileConverter {
  static File fromSql(String homeDir, sql.CompleteFile f) {
    final metadata = f.image?.run((obj) => Metadata(
          lastUpdated: obj.lastUpdated,
          fileEtag: obj.fileEtag,
          imageWidth: obj.width,
          imageHeight: obj.height,
          exif: obj.exifRaw?.run((e) => Exif.fromJson(jsonDecode(e))),
        ));
    return File(
      path: "remote.php/dav/files/$homeDir/${f.accountFile.relativePath}",
      contentLength: f.file.contentLength,
      contentType: f.file.contentType,
      etag: f.file.etag,
      lastModified: f.file.lastModified,
      isCollection: f.file.isCollection,
      usedBytes: f.file.usedBytes,
      hasPreview: f.file.hasPreview,
      fileId: f.file.fileId,
      isFavorite: f.accountFile.isFavorite,
      ownerId: f.file.ownerId?.toCi(),
      trashbinFilename: f.trash?.filename,
      trashbinOriginalLocation: f.trash?.originalLocation,
      trashbinDeletionTime: f.trash?.deletionTime,
      metadata: metadata,
      isArchived: f.accountFile.isArchived,
      overrideDateTime: f.accountFile.overrideDateTime,
    );
  }

  static sql.CompleteFileCompanion toSql(sql.Account? account, File file) {
    final dbFile = sql.FilesCompanion(
      server: account == null ? const Value.absent() : Value(account.server),
      fileId: Value(file.fileId!),
      contentLength: Value(file.contentLength),
      contentType: Value(file.contentType),
      etag: Value(file.etag),
      lastModified: Value(file.lastModified),
      isCollection: Value(file.isCollection),
      usedBytes: Value(file.usedBytes),
      hasPreview: Value(file.hasPreview),
      ownerId: Value(file.ownerId!.toCaseInsensitiveString()),
    );
    final dbAccountFile = sql.AccountFilesCompanion(
      account: account == null ? const Value.absent() : Value(account.rowId),
      relativePath: Value(file.strippedPathWithEmpty),
      isFavorite: Value(file.isFavorite),
      isArchived: Value(file.isArchived),
      overrideDateTime: Value(file.overrideDateTime),
    );
    final dbImage = file.metadata?.run((m) => sql.ImagesCompanion.insert(
          lastUpdated: m.lastUpdated,
          fileEtag: Value(m.fileEtag),
          width: Value(m.imageWidth),
          height: Value(m.imageHeight),
          exifRaw: Value(m.exif?.toJson().run((j) => jsonEncode(j))),
          dateTimeOriginal: Value(m.exif?.dateTimeOriginal),
        ));
    final dbTrash = file.trashbinDeletionTime == null
        ? null
        : sql.TrashesCompanion.insert(
            filename: file.trashbinFilename!,
            originalLocation: file.trashbinOriginalLocation!,
            deletionTime: file.trashbinDeletionTime!,
          );
    return sql.CompleteFileCompanion(dbFile, dbAccountFile, dbImage, dbTrash);
  }
}
