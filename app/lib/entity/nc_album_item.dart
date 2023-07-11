import 'package:nc_photos/entity/file.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_common/string_extension.dart';
import 'package:to_string/to_string.dart';

part 'nc_album_item.g.dart';

@ToString(ignoreNull: true)
class NcAlbumItem {
  const NcAlbumItem({
    required this.path,
    required this.fileId,
    this.contentLength,
    this.contentType,
    this.etag,
    this.lastModified,
    this.hasPreview,
    this.isFavorite,
    this.fileMetadataWidth,
    this.fileMetadataHeight,
  });

  @override
  String toString() => _$toString();

  final String path;
  final int fileId;
  final int? contentLength;
  final String? contentType;
  final String? etag;
  final DateTime? lastModified;
  final bool? hasPreview;
  final bool? isFavorite;
  final int? fileMetadataWidth;
  final int? fileMetadataHeight;
}

extension NcAlbumItemExtension on NcAlbumItem {
  /// Return the path of this file with the DAV part stripped
  ///
  /// WebDAV file path: remote.php/dav/photos/{userId}/albums/{album}/{strippedPath}.
  /// If this path points to the user's root album path, return "."
  String get strippedPath {
    if (!path.startsWith("${api.ApiPhotos.path}/")) {
      throw ArgumentError("Unsupported path: $path");
    }
    var begin = "${api.ApiPhotos.path}/".length;
    begin = path.indexOf("/", begin);
    if (begin == -1) {
      throw ArgumentError("Unsupported path: $path");
    }
    // /albums/{album}/{strippedPath}
    if (path.slice(begin, begin + 7) != "/albums") {
      throw ArgumentError("Unsupported path: $path");
    }
    begin += 8;
    // {album}/{strippedPath}
    begin = path.indexOf("/", begin);
    if (begin == -1) {
      return ".";
    }
    return path.slice(begin + 1);
  }

  bool compareIdentity(NcAlbumItem other) => fileId == other.fileId;

  int get identityHashCode => fileId.hashCode;

  static int identityComparator(NcAlbumItem a, NcAlbumItem b) =>
      a.fileId.compareTo(b.fileId);

  File toFile() {
    Metadata? metadata;
    if (fileMetadataWidth != null && fileMetadataHeight != null) {
      metadata = Metadata(
        imageWidth: fileMetadataWidth,
        imageHeight: fileMetadataHeight,
      );
    }
    return File(
      path: path,
      fileId: fileId,
      contentLength: contentLength,
      contentType: contentType,
      etag: etag,
      lastModified: lastModified,
      hasPreview: hasPreview,
      isFavorite: isFavorite,
      metadata: metadata,
    );
  }
}
