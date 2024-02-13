// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$AlbumItemNpLog on AlbumItem {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("entity.album.item.AlbumItem");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$AlbumItemToString on AlbumItem {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "AlbumItem")} {addedBy: $addedBy, addedAt: $addedAt}";
  }
}

extension _$AlbumFileItemToString on AlbumFileItem {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AlbumFileItem {addedBy: $addedBy, addedAt: $addedAt, file: ${file.fdPath}, ownerId: $ownerId}";
  }
}

extension _$AlbumLabelItemToString on AlbumLabelItem {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AlbumLabelItem {addedBy: $addedBy, addedAt: $addedAt, text: $text}";
  }
}
