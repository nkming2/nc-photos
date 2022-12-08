// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file.dart';

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ImageLocationToString on ImageLocation {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ImageLocation {version: $version, ${name == null ? "" : "name: $name, "}${latitude == null ? "" : "latitude: ${latitude!.toStringAsFixed(3)}, "}${longitude == null ? "" : "longitude: ${longitude!.toStringAsFixed(3)}, "}${countryCode == null ? "" : "countryCode: $countryCode, "}${admin1 == null ? "" : "admin1: $admin1, "}${admin2 == null ? "" : "admin2: $admin2"}}";
  }
}

extension _$MetadataToString on Metadata {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Metadata {lastUpdated: $lastUpdated, ${fileEtag == null ? "" : "fileEtag: $fileEtag, "}${imageWidth == null ? "" : "imageWidth: $imageWidth, "}${imageHeight == null ? "" : "imageHeight: $imageHeight, "}${exif == null ? "" : "exif: $exif"}}";
  }
}

extension _$FileToString on File {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "File {path: $path, ${contentLength == null ? "" : "contentLength: $contentLength, "}${contentType == null ? "" : "contentType: $contentType, "}${etag == null ? "" : "etag: $etag, "}${lastModified == null ? "" : "lastModified: $lastModified, "}${isCollection == null ? "" : "isCollection: $isCollection, "}${usedBytes == null ? "" : "usedBytes: $usedBytes, "}${hasPreview == null ? "" : "hasPreview: $hasPreview, "}${fileId == null ? "" : "fileId: $fileId, "}${isFavorite == null ? "" : "isFavorite: $isFavorite, "}${ownerId == null ? "" : "ownerId: $ownerId, "}${ownerDisplayName == null ? "" : "ownerDisplayName: $ownerDisplayName, "}${trashbinFilename == null ? "" : "trashbinFilename: $trashbinFilename, "}${trashbinOriginalLocation == null ? "" : "trashbinOriginalLocation: $trashbinOriginalLocation, "}${trashbinDeletionTime == null ? "" : "trashbinDeletionTime: $trashbinDeletionTime, "}${metadata == null ? "" : "metadata: $metadata, "}${isArchived == null ? "" : "isArchived: $isArchived, "}${overrideDateTime == null ? "" : "overrideDateTime: $overrideDateTime, "}${location == null ? "" : "location: $location"}}";
  }
}
