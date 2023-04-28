import 'package:copy_with/copy_with.dart';
import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:np_common/string_extension.dart';
import 'package:to_string/to_string.dart';

part 'nc_album.g.dart';

/// Server-side album since Nextcloud 25
@toString
@genCopyWith
class NcAlbum with EquatableMixin {
  NcAlbum({
    required String path,
    required this.lastPhoto,
    required this.nbItems,
    required this.location,
    required this.dateStart,
    required this.dateEnd,
    required this.collaborators,
  }) : path = path.trimAny("/");

  static NcAlbum createNew({
    required Account account,
    required String name,
  }) {
    return NcAlbum(
      path: "remote.php/dav/photos/${account.userId}/albums/$name",
      lastPhoto: null,
      nbItems: 0,
      location: null,
      dateStart: null,
      dateEnd: null,
      collaborators: const [],
    );
  }

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [
        path,
        lastPhoto,
        nbItems,
        location,
        dateStart,
        dateEnd,
        collaborators,
      ];

  final String path;

  /// File ID of the last photo
  ///
  /// The API will return -1 if there's no photos in the album. It's mapped to
  /// null here instead
  final int? lastPhoto;

  /// Items count
  final int nbItems;
  final String? location;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final List<NcAlbumCollaborator> collaborators;
}

extension NcAlbumExtension on NcAlbum {
  /// Return the path of this file with the DAV part stripped
  ///
  /// WebDAV file path: remote.php/dav/photos/{userId}/albums/{strippedPath}.
  /// If this path points to the user's root album path, return "."
  String get strippedPath {
    if (!path.startsWith("remote.php/dav/photos/")) {
      return path;
    }
    var begin = "remote.php/dav/photos/".length;
    begin = path.indexOf("/", begin);
    if (begin == -1) {
      return path;
    }
    if (path.slice(begin, begin + 7) != "/albums") {
      return path;
    }
    // /albums/
    begin += 8;
    final stripped = path.slice(begin);
    if (stripped.isEmpty) {
      return ".";
    } else {
      return stripped;
    }
  }

  String getRenamedPath(String newName) {
    final i = path.indexOf("albums/");
    if (i == -1) {
      throw StateError("Invalid path: $path");
    }
    return "${path.substring(0, i + "albums/".length)}$newName";
  }

  int get count => nbItems;

  bool compareIdentity(NcAlbum other) {
    return path == other.path;
  }

  int get identityHashCode => path.hashCode;
}

class NcAlbumCollaborator {}
