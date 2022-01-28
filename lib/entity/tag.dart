import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/json_util.dart' as json_util;
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/type.dart';

class Tag with EquatableMixin {
  const Tag({
    required this.id,
    required this.displayName,
    this.userVisible,
    this.userAssignable,
    this.canAssign,
  });

  factory Tag.fromJson(JsonObj json) => Tag(
        id: json["id"],
        displayName: json["displayName"],
        userVisible: json_util.boolFromJson(json["userVisible"]),
        userAssignable: json_util.boolFromJson(json["userAssignable"]),
        canAssign: json_util.boolFromJson(json["canAssign"]),
      );

  JsonObj toJson() => {
        "id": id,
        "displayName": displayName,
        if (userVisible != null) "userVisible": userVisible,
        if (userAssignable != null) "userAssignable": userAssignable,
        if (canAssign != null) "canAssign": canAssign,
      };

  @override
  toString() {
    final buffer = StringBuffer();
    buffer.write("$runtimeType {"
        "id: $id, "
        "displayName: '$displayName', ");
    if (userVisible != null) {
      buffer.write("userVisible: $userVisible, ");
    }
    if (userAssignable != null) {
      buffer.write("userAssignable: $userAssignable, ");
    }
    if (canAssign != null) {
      buffer.write("canAssign: $canAssign, ");
    }
    buffer.write("}");
    return buffer.toString();
  }

  Tag copyWith({
    int? id,
    String? displayName,
    OrNull<bool>? userVisible,
    OrNull<bool>? userAssignable,
    OrNull<bool>? canAssign,
  }) =>
      Tag(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        userVisible: userVisible == null ? this.userVisible : userVisible.obj,
        userAssignable:
            userAssignable == null ? this.userAssignable : userAssignable.obj,
        canAssign: canAssign == null ? this.canAssign : canAssign.obj,
      );

  @override
  get props => [
        id,
        displayName,
        userVisible,
        userAssignable,
        canAssign,
      ];

  final int id;
  final String displayName;
  final bool? userVisible;
  final bool? userAssignable;
  final bool? canAssign;
}

extension TagExtension on Tag {
  /// Compare the server identity of two Tags
  ///
  /// Return true if two Tags point to the same tag on server. Be careful that
  /// this does NOT mean that the two Tags are identical
  bool compareServerIdentity(Tag other) {
    return id == other.id && displayName == other.displayName;
  }
}

class TagRepo {
  const TagRepo(this.dataSrc);

  /// See [TagDataSource.listByFile]
  Future<List<Tag>> listByFile(Account account, File file) =>
      dataSrc.listByFile(account, file);

  final TagDataSource dataSrc;
}

abstract class TagDataSource {
  /// List all tags associated with [file]
  Future<List<Tag>> listByFile(Account account, File file);
}
