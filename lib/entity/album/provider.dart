import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/iterable_extension.dart';

abstract class AlbumProvider with EquatableMixin {
  const AlbumProvider();

  factory AlbumProvider.fromJson(Map<String, dynamic> json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumStaticProvider._type:
        return AlbumStaticProvider.fromJson(content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  Map<String, dynamic> toJson() {
    String getType() {
      if (this is AlbumStaticProvider) {
        return AlbumStaticProvider._type;
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
  toString({bool isDeep = false});

  Map<String, dynamic> _toContentJson();

  static final _log = Logger("entity.album.provider.AlbumProvider");
}

class AlbumStaticProvider extends AlbumProvider {
  AlbumStaticProvider({
    @required List<AlbumItem> items,
  }) : this.items = UnmodifiableListView(items);

  factory AlbumStaticProvider.fromJson(Map<String, dynamic> json) {
    return AlbumStaticProvider(
      items: (json["items"] as List)
          .map((e) => AlbumItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  toString({bool isDeep = false}) {
    final itemsStr =
        isDeep ? items.toReadableString() : "List {length: ${items.length}}";
    return "$runtimeType {"
        "items: $itemsStr, "
        "}";
  }

  @override
  get props => [
        items,
      ];

  @override
  _toContentJson() {
    return {
      "items": items.map((e) => e.toJson()).toList(),
    };
  }

  /// Immutable list of items. Modifying the list will result in an error
  final List<AlbumItem> items;

  static const _type = "static";
}
