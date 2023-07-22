import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/face_recognition_person.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/nc_album.dart';
import 'package:nc_photos/entity/nc_album_item.dart';
import 'package:nc_photos/entity/recognize_face.dart';
import 'package:nc_photos/entity/recognize_face_item.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_common/ci_string.dart';
import 'package:np_common/type.dart';

extension SqlTagListExtension on List<sql.Tag> {
  Future<List<Tag>> convertToAppTag() {
    return computeAll(SqliteTagConverter.fromSql);
  }
}

extension AppTagListExtension on List<Tag> {
  Future<List<sql.TagsCompanion>> convertToTagCompanion(
      sql.Account? dbAccount) {
    return map((t) => {
          "account": dbAccount,
          "tag": t,
        }).computeAll(_convertAppTag);
  }
}

extension SqlFaceRecognitionPersonListExtension
    on List<sql.FaceRecognitionPerson> {
  Future<List<FaceRecognitionPerson>> convertToAppFaceRecognitionPerson() {
    return computeAll(SqliteFaceRecognitionPersonConverter.fromSql);
  }
}

extension AppFaceRecognitionPersonListExtension on List<FaceRecognitionPerson> {
  Future<List<sql.FaceRecognitionPersonsCompanion>>
      convertToFaceRecognitionPersonCompanion(sql.Account? dbAccount) {
    return map((p) => {
          "account": dbAccount,
          "person": p,
        }).computeAll(_convertAppFaceRecognitionPerson);
  }
}

extension SqlRecognizeFaceListExtension on List<sql.RecognizeFace> {
  Future<List<RecognizeFace>> convertToAppRecognizeFace() {
    return computeAll(SqliteRecognizeFaceConverter.fromSql);
  }
}

extension AppRecognizeFaceListExtension on List<RecognizeFace> {
  Future<List<sql.RecognizeFacesCompanion>> convertToRecognizeFaceCompanion(
      sql.Account? dbAccount) {
    return map((f) => {
          "account": dbAccount,
          "face": f,
        }).computeAll(_convertAppRecognizeFace);
  }
}

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
      // replace with the original etag when this album was cached
      albumFile: albumFile.copyWith(etag: OrNull(album.fileEtag)),
      savedVersion: album.version,
    );
  }

  static sql.CompleteAlbumCompanion toSql(
      Album album, int albumFileRowId, String albumFileEtag) {
    final providerJson = album.provider.toJson();
    final coverProviderJson = album.coverProvider.toJson();
    final sortProviderJson = album.sortProvider.toJson();
    final dbAlbum = sql.AlbumsCompanion.insert(
      file: albumFileRowId,
      fileEtag: Value(albumFileEtag),
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

class SqliteFileDescriptorConverter {
  static FileDescriptor fromSql(String userId, sql.FileDescriptor f) {
    return FileDescriptor(
      fdPath: "remote.php/dav/files/$userId/${f.relativePath}",
      fdId: f.fileId,
      fdMime: f.contentType,
      fdIsArchived: f.isArchived ?? false,
      fdIsFavorite: f.isFavorite ?? false,
      fdDateTime: f.bestDateTime,
    );
  }
}

class SqliteFileConverter {
  static File fromSql(String userId, sql.CompleteFile f) {
    final metadata = f.image?.run((obj) => Metadata(
          lastUpdated: obj.lastUpdated,
          fileEtag: obj.fileEtag,
          imageWidth: obj.width,
          imageHeight: obj.height,
          exif: obj.exifRaw?.run((e) => Exif.fromJson(jsonDecode(e))),
        ));
    final location = f.imageLocation?.run((obj) => ImageLocation(
          version: obj.version,
          name: obj.name,
          latitude: obj.latitude,
          longitude: obj.longitude,
          countryCode: obj.countryCode,
          admin1: obj.admin1,
          admin2: obj.admin2,
        ));
    return File(
      path: "remote.php/dav/files/$userId/${f.accountFile.relativePath}",
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
      ownerDisplayName: f.file.ownerDisplayName,
      trashbinFilename: f.trash?.filename,
      trashbinOriginalLocation: f.trash?.originalLocation,
      trashbinDeletionTime: f.trash?.deletionTime,
      metadata: metadata,
      isArchived: f.accountFile.isArchived,
      overrideDateTime: f.accountFile.overrideDateTime,
      location: location,
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
      ownerDisplayName: Value(file.ownerDisplayName),
    );
    final dbAccountFile = sql.AccountFilesCompanion(
      account: account == null ? const Value.absent() : Value(account.rowId),
      relativePath: Value(file.strippedPathWithEmpty),
      isFavorite: Value(file.isFavorite),
      isArchived: Value(file.isArchived),
      overrideDateTime: Value(file.overrideDateTime),
      bestDateTime: Value(file.bestDateTime),
    );
    final dbImage = file.metadata?.run((m) => sql.ImagesCompanion.insert(
          lastUpdated: m.lastUpdated,
          fileEtag: Value(m.fileEtag),
          width: Value(m.imageWidth),
          height: Value(m.imageHeight),
          exifRaw: Value(m.exif?.toJson().run((j) => jsonEncode(j))),
          dateTimeOriginal: Value(m.exif?.dateTimeOriginal),
        ));
    final dbImageLocation =
        file.location?.run((l) => sql.ImageLocationsCompanion.insert(
              version: l.version,
              name: Value(l.name),
              latitude: Value(l.latitude),
              longitude: Value(l.longitude),
              countryCode: Value(l.countryCode),
              admin1: Value(l.admin1),
              admin2: Value(l.admin2),
            ));
    final dbTrash = file.trashbinDeletionTime == null
        ? null
        : sql.TrashesCompanion.insert(
            filename: file.trashbinFilename!,
            originalLocation: file.trashbinOriginalLocation!,
            deletionTime: file.trashbinDeletionTime!,
          );
    return sql.CompleteFileCompanion(
        dbFile, dbAccountFile, dbImage, dbImageLocation, dbTrash);
  }
}

class SqliteTagConverter {
  static Tag fromSql(sql.Tag tag) => Tag(
        id: tag.tagId,
        displayName: tag.displayName,
        userVisible: tag.userVisible,
        userAssignable: tag.userAssignable,
      );

  static sql.TagsCompanion toSql(sql.Account? dbAccount, Tag tag) =>
      sql.TagsCompanion(
        server:
            dbAccount == null ? const Value.absent() : Value(dbAccount.server),
        tagId: Value(tag.id),
        displayName: Value(tag.displayName),
        userVisible: Value(tag.userVisible),
        userAssignable: Value(tag.userAssignable),
      );
}

class SqliteFaceRecognitionPersonConverter {
  static FaceRecognitionPerson fromSql(sql.FaceRecognitionPerson person) =>
      FaceRecognitionPerson(
        name: person.name,
        thumbFaceId: person.thumbFaceId,
        count: person.count,
      );

  static sql.FaceRecognitionPersonsCompanion toSql(
          sql.Account? dbAccount, FaceRecognitionPerson person) =>
      sql.FaceRecognitionPersonsCompanion(
        account:
            dbAccount == null ? const Value.absent() : Value(dbAccount.rowId),
        name: Value(person.name),
        thumbFaceId: Value(person.thumbFaceId),
        count: Value(person.count),
      );
}

class SqliteNcAlbumConverter {
  static NcAlbum fromSql(String userId, sql.NcAlbum ncAlbum) {
    final json = ncAlbum.collaborators
        .run((obj) => (jsonDecode(obj) as List).cast<Map>());
    return NcAlbum(
      path: "${api.ApiPhotos.path}/$userId/albums/${ncAlbum.relativePath}",
      lastPhoto: ncAlbum.lastPhoto,
      nbItems: ncAlbum.nbItems,
      location: ncAlbum.location,
      dateStart: ncAlbum.dateStart,
      dateEnd: ncAlbum.dateEnd,
      collaborators: json
          .map((e) => NcAlbumCollaborator.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  static sql.NcAlbumsCompanion toSql(sql.Account? dbAccount, NcAlbum ncAlbum) =>
      sql.NcAlbumsCompanion(
        account:
            dbAccount == null ? const Value.absent() : Value(dbAccount.rowId),
        relativePath: Value(ncAlbum.strippedPath),
        lastPhoto: Value(ncAlbum.lastPhoto),
        nbItems: Value(ncAlbum.nbItems),
        location: Value(ncAlbum.location),
        dateStart: Value(ncAlbum.dateStart),
        dateEnd: Value(ncAlbum.dateEnd),
        collaborators: Value(
            jsonEncode(ncAlbum.collaborators.map((c) => c.toJson()).toList())),
      );
}

class SqliteNcAlbumItemConverter {
  static NcAlbumItem fromSql(
          String userId, String albumRelativePath, sql.NcAlbumItem item) =>
      NcAlbumItem(
        path:
            "${api.ApiPhotos.path}/$userId/albums/$albumRelativePath/${item.relativePath}",
        fileId: item.fileId,
        contentLength: item.contentLength,
        contentType: item.contentType,
        etag: item.etag,
        lastModified: item.lastModified,
        hasPreview: item.hasPreview,
        isFavorite: item.isFavorite,
        fileMetadataWidth: item.fileMetadataWidth,
        fileMetadataHeight: item.fileMetadataHeight,
      );

  static sql.NcAlbumItemsCompanion toSql(
    sql.NcAlbum parent,
    NcAlbumItem item,
  ) =>
      sql.NcAlbumItemsCompanion(
        parent: Value(parent.rowId),
        relativePath: Value(item.strippedPath),
        fileId: Value(item.fileId),
        contentLength: Value(item.contentLength),
        contentType: Value(item.contentType),
        etag: Value(item.etag),
        lastModified: Value(item.lastModified),
        hasPreview: Value(item.hasPreview),
        isFavorite: Value(item.isFavorite),
        fileMetadataWidth: Value(item.fileMetadataWidth),
        fileMetadataHeight: Value(item.fileMetadataHeight),
      );
}

class SqliteRecognizeFaceConverter {
  static RecognizeFace fromSql(sql.RecognizeFace face) => RecognizeFace(
        label: face.label,
      );

  static sql.RecognizeFacesCompanion toSql(
          sql.Account? dbAccount, RecognizeFace face) =>
      sql.RecognizeFacesCompanion(
        account:
            dbAccount == null ? const Value.absent() : Value(dbAccount.rowId),
        label: Value(face.label),
      );
}

class SqliteRecognizeFaceItemConverter {
  static RecognizeFaceItem fromSql(
          String userId, String faceLabel, sql.RecognizeFaceItem item) =>
      RecognizeFaceItem(
        path:
            "${api.ApiRecognize.path}/$userId/faces/$faceLabel/${item.relativePath}",
        fileId: item.fileId,
        contentLength: item.contentLength,
        contentType: item.contentType,
        etag: item.etag,
        lastModified: item.lastModified,
        hasPreview: item.hasPreview,
        realPath: item.realPath,
        isFavorite: item.isFavorite,
        fileMetadataWidth: item.fileMetadataWidth,
        fileMetadataHeight: item.fileMetadataHeight,
        faceDetections: item.faceDetections
            ?.run((obj) => (jsonDecode(obj) as List).cast<JsonObj>()),
      );

  static sql.RecognizeFaceItemsCompanion toSql(
    sql.RecognizeFace parent,
    RecognizeFaceItem item,
  ) =>
      sql.RecognizeFaceItemsCompanion(
        parent: Value(parent.rowId),
        relativePath: Value(item.strippedPath),
        fileId: Value(item.fileId),
        contentLength: Value(item.contentLength),
        contentType: Value(item.contentType),
        etag: Value(item.etag),
        lastModified: Value(item.lastModified),
        hasPreview: Value(item.hasPreview),
        realPath: Value(item.realPath),
        isFavorite: Value(item.isFavorite),
        fileMetadataWidth: Value(item.fileMetadataWidth),
        fileMetadataHeight: Value(item.fileMetadataHeight),
        faceDetections:
            Value(item.faceDetections?.run((obj) => jsonEncode(obj))),
      );
}

sql.TagsCompanion _convertAppTag(Map map) {
  final account = map["account"] as sql.Account?;
  final tag = map["tag"] as Tag;
  return SqliteTagConverter.toSql(account, tag);
}

sql.FaceRecognitionPersonsCompanion _convertAppFaceRecognitionPerson(Map map) {
  final account = map["account"] as sql.Account?;
  final person = map["person"] as FaceRecognitionPerson;
  return SqliteFaceRecognitionPersonConverter.toSql(account, person);
}

sql.RecognizeFacesCompanion _convertAppRecognizeFace(Map map) {
  final account = map["account"] as sql.Account?;
  final face = map["face"] as RecognizeFace;
  return SqliteRecognizeFaceConverter.toSql(account, face);
}
