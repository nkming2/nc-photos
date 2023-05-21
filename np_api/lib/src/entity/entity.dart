import 'package:equatable/equatable.dart';
import 'package:np_common/type.dart';
import 'package:to_string/to_string.dart';

part 'entity.g.dart';

@toString
class Face with EquatableMixin {
  const Face({
    required this.id,
    required this.fileId,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        id,
        fileId,
      ];

  final int id;
  final int fileId;
}

@toString
class Favorite with EquatableMixin {
  const Favorite({
    required this.href,
    required this.fileId,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        href,
        fileId,
      ];

  final String href;
  final int fileId;
}

@ToString(ignoreNull: true)
class File with EquatableMixin {
  const File({
    required this.href,
    this.lastModified,
    this.etag,
    this.contentType,
    this.isCollection,
    this.contentLength,
    this.fileId,
    this.favorite,
    this.ownerId,
    this.ownerDisplayName,
    this.hasPreview,
    this.trashbinFilename,
    this.trashbinOriginalLocation,
    this.trashbinDeletionTime,
    this.customProperties,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        href,
        lastModified,
        etag,
        contentType,
        isCollection,
        contentLength,
        fileId,
        favorite,
        ownerId,
        ownerDisplayName,
        hasPreview,
        trashbinFilename,
        trashbinOriginalLocation,
        trashbinDeletionTime,
        customProperties,
      ];

  final String href;
  final DateTime? lastModified;
  final String? etag;
  final String? contentType;
  final bool? isCollection;
  final int? contentLength;
  final int? fileId;
  final bool? favorite;
  final String? ownerId;
  final String? ownerDisplayName;
  final bool? hasPreview;
  final String? trashbinFilename;
  final String? trashbinOriginalLocation;
  final DateTime? trashbinDeletionTime;
  final Map<String, String>? customProperties;
}

@toString
class NcAlbum with EquatableMixin {
  const NcAlbum({
    required this.href,
    required this.lastPhoto,
    required this.nbItems,
    required this.location,
    required this.dateRange,
    required this.collaborators,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props =>
      [href, lastPhoto, nbItems, location, dateRange, collaborators];

  final String href;
  final int? lastPhoto;
  final int? nbItems;
  final String? location;
  final JsonObj? dateRange;
  final List<NcAlbumCollaborator> collaborators;
}

@toString
class NcAlbumCollaborator with EquatableMixin {
  const NcAlbumCollaborator({
    required this.id,
    required this.label,
    required this.type,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [id, label, type];

  final String id;
  final String label;
  final int type;
}

@ToString(ignoreNull: true)
class NcAlbumItem with EquatableMixin {
  const NcAlbumItem({
    required this.href,
    this.fileId,
    this.contentLength,
    this.contentType,
    this.etag,
    this.lastModified,
    this.hasPreview,
    this.favorite,
    this.fileMetadataSize,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        href,
        fileId,
        contentLength,
        contentType,
        etag,
        lastModified,
        hasPreview,
        favorite,
        fileMetadataSize,
      ];

  final String href;
  final int? fileId;
  final int? contentLength;
  final String? contentType;
  final String? etag;
  final DateTime? lastModified;
  final bool? hasPreview;
  final bool? favorite;
  final JsonObj? fileMetadataSize;
}

@toString
class Person with EquatableMixin {
  const Person({
    required this.name,
    required this.thumbFaceId,
    required this.count,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        name,
        thumbFaceId,
        count,
      ];

  final String name;
  final int thumbFaceId;
  final int count;
}

@toString
class Share with EquatableMixin {
  const Share({
    required this.id,
    required this.shareType,
    required this.stime,
    required this.uidOwner,
    required this.displaynameOwner,
    required this.uidFileOwner,
    required this.path,
    required this.itemType,
    required this.mimeType,
    required this.itemSource,
    required this.shareWith,
    required this.shareWithDisplayName,
    required this.url,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        id,
        shareType,
        stime,
        uidOwner,
        displaynameOwner,
        uidFileOwner,
        path,
        itemType,
        mimeType,
        itemSource,
        shareWith,
        shareWithDisplayName,
        url,
      ];

  final String id;
  final int shareType;
  final int stime;
  final String uidOwner;
  final String displaynameOwner;
  final String uidFileOwner;
  final String path;
  final String itemType;
  final String mimeType;
  final int itemSource;
  final String? shareWith;
  final String shareWithDisplayName;
  final String? url;
}

@toString
class Sharee with EquatableMixin {
  const Sharee({
    required this.type,
    required this.label,
    required this.shareType,
    required this.shareWith,
    required this.shareWithDisplayNameUnique,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        type,
        label,
        shareType,
        shareWith,
        shareWithDisplayNameUnique,
      ];

  final String type;
  final String label;
  final int shareType;
  final String shareWith;
  final String? shareWithDisplayNameUnique;
}

@toString
class Status with EquatableMixin {
  const Status({
    required this.version,
    required this.versionString,
    required this.productName,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        version,
        versionString,
        productName,
      ];

  final String version;
  final String versionString;
  final String productName;
}

@toString
class Tag with EquatableMixin {
  const Tag({
    required this.href,
    required this.id,
    required this.displayName,
    required this.userVisible,
    required this.userAssignable,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        href,
        id,
        displayName,
        userVisible,
        userAssignable,
      ];

  final String href;
  final int id;
  final String displayName;
  final bool userVisible;
  final bool userAssignable;
}

@toString
class TaggedFile with EquatableMixin {
  const TaggedFile({
    required this.href,
    required this.fileId,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        href,
        fileId,
      ];

  final String href;
  final int fileId;
}
