import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';
import 'package:to_string/to_string.dart';

part 'cover_provider.g.dart';

@npLog
abstract class AlbumCoverProvider with EquatableMixin {
  const AlbumCoverProvider();

  factory AlbumCoverProvider.fromJson(JsonObj json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumAutoCoverProvider._type:
        return AlbumAutoCoverProvider.fromJson(content.cast<String, dynamic>());
      case AlbumManualCoverProvider._type:
        return AlbumManualCoverProvider.fromJson(
            content.cast<String, dynamic>());
      case AlbumMemoryCoverProvider._type:
        return AlbumMemoryCoverProvider.fromJson(
            content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  JsonObj toJson() {
    String getType() {
      if (this is AlbumAutoCoverProvider) {
        return AlbumAutoCoverProvider._type;
      } else if (this is AlbumManualCoverProvider) {
        return AlbumManualCoverProvider._type;
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
  String toString();

  FileDescriptor? getCover(Album album);

  JsonObj _toContentJson();

  static final _log = _$AlbumCoverProviderNpLog.log;
}

/// Cover selected automatically by us
@toString
class AlbumAutoCoverProvider extends AlbumCoverProvider {
  const AlbumAutoCoverProvider({
    this.coverFile,
  });

  factory AlbumAutoCoverProvider.fromJson(JsonObj json) {
    return AlbumAutoCoverProvider(
      coverFile: json["coverFile"] == null
          ? null
          : FileDescriptor.fromJson(json["coverFile"].cast<String, dynamic>()),
    );
  }

  static FileDescriptor? getCoverByItems(List<AlbumItem> items) {
    return items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .where((element) =>
            file_util.isSupportedFormat(element) &&
            (element.hasPreview ?? false))
        .sorted(compareFileDateTimeDescending)
        .firstOrNull;
  }

  @override
  String toString() => _$toString();

  @override
  FileDescriptor? getCover(Album album) {
    if (coverFile == null) {
      // use the latest file as cover
      return getCoverByItems(AlbumStaticProvider.of(album).items);
    } else {
      return coverFile;
    }
  }

  @override
  List<Object?> get props => [
        coverFile,
      ];

  @override
  JsonObj _toContentJson() {
    return {
      if (coverFile != null) "coverFile": coverFile!.toFdJson(),
    };
  }

  final FileDescriptor? coverFile;

  static const _type = "auto";
}

/// Cover picked by user
@toString
class AlbumManualCoverProvider extends AlbumCoverProvider {
  const AlbumManualCoverProvider({
    required this.coverFile,
  });

  factory AlbumManualCoverProvider.fromJson(JsonObj json) {
    return AlbumManualCoverProvider(
      coverFile:
          FileDescriptor.fromJson(json["coverFile"].cast<String, dynamic>()),
    );
  }

  @override
  String toString() => _$toString();

  @override
  FileDescriptor? getCover(Album album) => coverFile;

  @override
  List<Object?> get props => [
        coverFile,
      ];

  @override
  JsonObj _toContentJson() {
    return {
      "coverFile": coverFile.toFdJson(),
    };
  }

  final FileDescriptor coverFile;

  static const _type = "manual";
}

/// Cover selected when building a Memory album
@toString
class AlbumMemoryCoverProvider extends AlbumCoverProvider {
  AlbumMemoryCoverProvider({
    required this.coverFile,
  });

  factory AlbumMemoryCoverProvider.fromJson(JsonObj json) {
    return AlbumMemoryCoverProvider(
      coverFile:
          FileDescriptor.fromJson(json["coverFile"].cast<String, dynamic>()),
    );
  }

  @override
  String toString() => _$toString();

  @override
  getCover(Album album) => coverFile;

  @override
  get props => [
        coverFile,
      ];

  @override
  _toContentJson() => {
        "coverFile": coverFile.toFdJson(),
      };

  final FileDescriptor coverFile;

  static const _type = "memory";
}
