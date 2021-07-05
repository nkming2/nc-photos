import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/iterable_extension.dart' as iterable_extension;

abstract class AlbumCoverProvider with EquatableMixin {
  const AlbumCoverProvider();

  factory AlbumCoverProvider.fromJson(Map<String, dynamic> json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumAutoCoverProvider._type:
        return AlbumAutoCoverProvider.fromJson(content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  Map<String, dynamic> toJson() {
    String getType() {
      if (this is AlbumAutoCoverProvider) {
        return AlbumAutoCoverProvider._type;
      } else {
        throw StateError("Unknwon subtype");
      }
    }

    return {
      "type": getType(),
      "content": _toContentJson(),
    };
  }

  @override
  toString();

  File getCover(Album album);

  Map<String, dynamic> _toContentJson();

  static final _log = Logger("entity.album.cover_provider.AlbumCoverProvider");
}

/// Cover selected automatically by us
class AlbumAutoCoverProvider extends AlbumCoverProvider {
  AlbumAutoCoverProvider({
    this.coverFile,
  });

  factory AlbumAutoCoverProvider.fromJson(Map<String, dynamic> json) {
    return AlbumAutoCoverProvider(
      coverFile: json["coverFile"] == null
          ? null
          : File.fromJson(json["coverFile"].cast<String, dynamic>()),
    );
  }

  @override
  toString() {
    return "$runtimeType {"
        "coverFile: '${coverFile?.path}', "
        "}";
  }

  File getCover(Album album) {
    if (coverFile == null) {
      try {
        // use the latest file as cover
        return AlbumStaticProvider.of(album)
            .items
            .whereType<AlbumFileItem>()
            .map((e) => e.file)
            .where((element) =>
                file_util.isSupportedFormat(element) && element.hasPreview)
            .sorted(compareFileDateTimeDescending)
            .first;
      } catch (_) {
        return null;
      }
    } else {
      return coverFile;
    }
  }

  @override
  get props => [
        coverFile,
      ];

  @override
  _toContentJson() {
    return {
      if (coverFile != null) "coverFile": coverFile.toJson(),
    };
  }

  final File coverFile;

  static const _type = "auto";
}
