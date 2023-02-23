// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity.dart';

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$FaceToString on Face {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Face {id: $id, fileId: $fileId}";
  }
}

extension _$FavoriteToString on Favorite {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Favorite {href: $href, fileId: $fileId}";
  }
}

extension _$FileToString on File {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "File {href: $href, ${lastModified == null ? "" : "lastModified: $lastModified, "}${etag == null ? "" : "etag: $etag, "}${contentType == null ? "" : "contentType: $contentType, "}${isCollection == null ? "" : "isCollection: $isCollection, "}${contentLength == null ? "" : "contentLength: $contentLength, "}${fileId == null ? "" : "fileId: $fileId, "}${favorite == null ? "" : "favorite: $favorite, "}${ownerId == null ? "" : "ownerId: $ownerId, "}${ownerDisplayName == null ? "" : "ownerDisplayName: $ownerDisplayName, "}${hasPreview == null ? "" : "hasPreview: $hasPreview, "}${trashbinFilename == null ? "" : "trashbinFilename: $trashbinFilename, "}${trashbinOriginalLocation == null ? "" : "trashbinOriginalLocation: $trashbinOriginalLocation, "}${trashbinDeletionTime == null ? "" : "trashbinDeletionTime: $trashbinDeletionTime, "}${customProperties == null ? "" : "customProperties: $customProperties"}}";
  }
}

extension _$PersonToString on Person {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Person {name: $name, thumbFaceId: $thumbFaceId, count: $count}";
  }
}

extension _$ShareToString on Share {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Share {id: $id, shareType: $shareType, stime: $stime, uidOwner: $uidOwner, displaynameOwner: $displaynameOwner, uidFileOwner: $uidFileOwner, path: $path, itemType: $itemType, mimeType: $mimeType, itemSource: $itemSource, shareWith: $shareWith, shareWithDisplayName: $shareWithDisplayName, url: $url}";
  }
}

extension _$ShareeToString on Sharee {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Sharee {type: $type, label: $label, shareType: $shareType, shareWith: $shareWith, shareWithDisplayNameUnique: $shareWithDisplayNameUnique}";
  }
}

extension _$TagToString on Tag {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Tag {href: $href, id: $id, displayName: $displayName, userVisible: $userVisible, userAssignable: $userAssignable}";
  }
}

extension _$TaggedFileToString on TaggedFile {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "TaggedFile {href: $href, fileId: $fileId}";
  }
}
