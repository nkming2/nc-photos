// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logAlbumItem = Logger("entity.album.item.AlbumItem");

extension _$AlbumItemNpLog on AlbumItem {
  // ignore: unused_element
  Logger get _log => _$logAlbumItem;
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
    return "AlbumFileItem {addedBy: $addedBy, addedAt: $addedAt, file: ${file.path}}";
  }
}

extension _$AlbumLabelItemToString on AlbumLabelItem {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AlbumLabelItem {addedBy: $addedBy, addedAt: $addedAt, text: $text}";
  }
}
