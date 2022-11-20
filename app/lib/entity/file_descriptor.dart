import 'package:equatable/equatable.dart';
import 'package:nc_photos/type.dart';
import 'package:path/path.dart' as path_lib;

int compareFileDescriptorDateTimeDescending(
    FileDescriptor x, FileDescriptor y) {
  final tmp = y.fdDateTime.compareTo(x.fdDateTime);
  if (tmp != 0) {
    return tmp;
  } else {
    // compare file name if files are modified at the same time
    return x.fdPath.compareTo(y.fdPath);
  }
}

class FileDescriptor with EquatableMixin {
  const FileDescriptor({
    required this.fdPath,
    required this.fdId,
    required this.fdMime,
    required this.fdIsArchived,
    required this.fdIsFavorite,
    required this.fdDateTime,
  });

  static FileDescriptor fromJson(JsonObj json) => FileDescriptor(
        fdPath: json["fdPath"],
        fdId: json["fdId"],
        fdMime: json["fdMime"],
        fdIsArchived: json["fdIsArchived"],
        fdIsFavorite: json["fdIsFavorite"],
        fdDateTime: json["fdDateTime"],
      );

  JsonObj toJson() => {
        "fdPath": fdPath,
        "fdId": fdId,
        "fdMime": fdMime,
        "fdIsArchived": fdIsArchived,
        "fdIsFavorite": fdIsFavorite,
        "fdDateTime": fdDateTime,
      };

  @override
  get props => [
        fdPath,
        fdId,
        fdMime,
        fdIsArchived,
        fdIsFavorite,
        fdDateTime,
      ];

  final String fdPath;
  final int fdId;
  final String? fdMime;
  final bool fdIsArchived;
  final bool fdIsFavorite;
  final DateTime fdDateTime;
}

extension FileDescriptorExtension on FileDescriptor {
  /// Return the path of this file with the DAV part stripped
  ///
  /// WebDAV file path: remote.php/dav/files/{username}/{strippedPath}. If this
  /// file points to the user's root dir, return "."
  ///
  /// See: [strippedPathWithEmpty]
  String get strippedPath {
    if (fdPath.contains("remote.php/dav/files")) {
      final position = fdPath.indexOf("/", "remote.php/dav/files/".length) + 1;
      if (position == 0) {
        // root dir path
        return ".";
      } else {
        return fdPath.substring(position);
      }
    } else {
      return fdPath;
    }
  }

  /// Return the path of this file with the DAV part stripped
  ///
  /// WebDAV file path: remote.php/dav/files/{username}/{strippedPath}. If this
  /// file points to the user's root dir, return an empty string
  ///
  /// See: [strippedPath]
  String get strippedPathWithEmpty {
    final path = strippedPath;
    return path == "." ? "" : path;
  }

  String get filename => path_lib.basename(fdPath);

  /// Compare the server identity of two Files
  ///
  /// Return true if two Files point to the same file on server. Be careful that
  /// this does NOT mean that the two Files are identical
  bool compareServerIdentity(FileDescriptor other) {
    try {
      return fdId == other.fdId;
    } catch (_) {
      return fdPath == other.fdPath;
    }
  }

  /// hashCode to be used with [compareServerIdentity]
  int get identityHashCode => fdId.hashCode;
}
