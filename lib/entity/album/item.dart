import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/type.dart';

List<AlbumItem> makeDistinctAlbumItems(List<AlbumItem> items) =>
    items.distinctIf(
        (a, b) =>
            a is AlbumFileItem &&
            b is AlbumFileItem &&
            a.file.path == b.file.path, (a) {
      if (a is AlbumFileItem) {
        return a.file.path.hashCode;
      } else {
        return Random().nextInt(0xFFFFFFFF);
      }
    });

abstract class AlbumItem {
  AlbumItem();

  factory AlbumItem.fromJson(JsonObj json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumFileItem._type:
        return AlbumFileItem.fromJson(content.cast<String, dynamic>());
      case AlbumLabelItem._type:
        return AlbumLabelItem.fromJson(content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  JsonObj toJson() {
    String getType() {
      if (this is AlbumFileItem) {
        return AlbumFileItem._type;
      } else if (this is AlbumLabelItem) {
        return AlbumLabelItem._type;
      } else {
        throw StateError("Unknwon subtype");
      }
    }

    return {
      "type": getType(),
      "content": toContentJson(),
    };
  }

  JsonObj toContentJson();

  static final _log = Logger("entity.album.AlbumItem");
}

class AlbumFileItem extends AlbumItem with EquatableMixin {
  AlbumFileItem({
    required this.file,
  });

  @override
  // ignore: hash_and_equals
  bool operator ==(Object? other) => equals(other, isDeep: true);

  bool equals(Object? other, {bool isDeep = false}) {
    if (other is AlbumFileItem) {
      return super == other && (file.equals(other.file, isDeep: isDeep));
    } else {
      return false;
    }
  }

  factory AlbumFileItem.fromJson(JsonObj json) {
    return AlbumFileItem(
      file: File.fromJson(json["file"].cast<String, dynamic>()),
    );
  }

  @override
  toString() {
    return "$runtimeType {"
        "file: $file"
        "}";
  }

  @override
  toContentJson() {
    return {
      "file": file.toJson(),
    };
  }

  AlbumFileItem minimize() => AlbumFileItem(
        file: file.copyWith(metadata: OrNull(null)),
      );

  @override
  get props => [
        // file is handled separately, see [equals]
      ];

  final File file;

  static const _type = "file";
}

class AlbumLabelItem extends AlbumItem with EquatableMixin {
  AlbumLabelItem({
    required this.text,
  });

  factory AlbumLabelItem.fromJson(JsonObj json) {
    return AlbumLabelItem(
      text: json["text"],
    );
  }

  @override
  toString() {
    return "$runtimeType {"
        "text: '$text', "
        "}";
  }

  @override
  toContentJson() {
    return {
      "text": text,
    };
  }

  @override
  get props => [
        text,
      ];

  final String text;

  static const _type = "label";
}
