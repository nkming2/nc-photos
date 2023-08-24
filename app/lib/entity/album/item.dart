import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/ci_string.dart';
import 'package:np_common/or_null.dart';
import 'package:np_common/type.dart';
import 'package:to_string/to_string.dart';

part 'item.g.dart';

@npLog
@toString
abstract class AlbumItem with EquatableMixin {
  AlbumItem({
    required this.addedBy,
    required DateTime addedAt,
  }) : addedAt = addedAt.toUtc();

  factory AlbumItem.fromJson(JsonObj json) {
    final addedBy = CiString(json["addedBy"]);
    final addedAt = DateTime.parse(json["addedAt"]);
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumFileItem._type:
        return AlbumFileItem.fromJson(
            content.cast<String, dynamic>(), addedBy, addedAt);
      case AlbumLabelItem._type:
        return AlbumLabelItem.fromJson(
            content.cast<String, dynamic>(), addedBy, addedAt);
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
      "addedBy": addedBy.toString(),
      "addedAt": addedAt.toIso8601String(),
    };
  }

  JsonObj toContentJson();

  @override
  String toString() => _$toString();

  @override
  get props => [
        addedBy,
        addedAt,
      ];

  final CiString addedBy;
  final DateTime addedAt;

  static final _log = _$AlbumItemNpLog.log;
}

@toString
class AlbumFileItem extends AlbumItem {
  AlbumFileItem({
    required CiString addedBy,
    required DateTime addedAt,
    required this.file,
  }) : super(addedBy: addedBy, addedAt: addedAt);

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

  factory AlbumFileItem.fromJson(
      JsonObj json, CiString addedBy, DateTime addedAt) {
    return AlbumFileItem(
      addedBy: addedBy,
      addedAt: addedAt,
      file: File.fromJson(json["file"].cast<String, dynamic>()),
    );
  }

  @override
  String toString() => _$toString();

  @override
  toContentJson() {
    return {
      "file": file.toJson(),
    };
  }

  AlbumFileItem copyWith({
    CiString? addedBy,
    DateTime? addedAt,
    File? file,
  }) {
    return AlbumFileItem(
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      file: file ?? this.file,
    );
  }

  AlbumFileItem minimize() => AlbumFileItem(
        addedBy: addedBy,
        addedAt: addedAt,
        file: file.copyWith(metadata: const OrNull(null)),
      );

  @override
  get props => [
        ...super.props,
        // file is handled separately, see [equals]
      ];

  final File file;

  static const _type = "file";
}

@toString
class AlbumLabelItem extends AlbumItem {
  AlbumLabelItem({
    required CiString addedBy,
    required DateTime addedAt,
    required this.text,
  }) : super(addedBy: addedBy, addedAt: addedAt);

  factory AlbumLabelItem.fromJson(
      JsonObj json, CiString addedBy, DateTime addedAt) {
    return AlbumLabelItem(
      addedBy: addedBy,
      addedAt: addedAt,
      text: json["text"],
    );
  }

  @override
  String toString() => _$toString();

  @override
  toContentJson() {
    return {
      "text": text,
    };
  }

  AlbumLabelItem copyWith({
    CiString? addedBy,
    DateTime? addedAt,
    String? text,
  }) {
    return AlbumLabelItem(
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      text: text ?? this.text,
    );
  }

  @override
  get props => [
        ...super.props,
        text,
      ];

  final String text;

  static const _type = "label";
}
