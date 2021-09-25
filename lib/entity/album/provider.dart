import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/type.dart';

abstract class AlbumProvider with EquatableMixin {
  const AlbumProvider();

  factory AlbumProvider.fromJson(JsonObj json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumStaticProvider._type:
        return AlbumStaticProvider.fromJson(content.cast<String, dynamic>());
      case AlbumDirProvider._type:
        return AlbumDirProvider.fromJson(content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  JsonObj toJson() {
    String getType() {
      if (this is AlbumStaticProvider) {
        return AlbumStaticProvider._type;
      } else if (this is AlbumDirProvider) {
        return AlbumDirProvider._type;
      } else {
        throw StateError("Unknwon subtype");
      }
    }

    return {
      "type": getType(),
      "content": toContentJson(),
    };
  }

  @protected
  JsonObj toContentJson();

  @override
  toString({bool isDeep = false});

  /// Return the date time associated with the latest item, or null
  DateTime? get latestItemTime;

  AlbumProvider copyWith();

  static final _log = Logger("entity.album.provider.AlbumProvider");
}

abstract class AlbumProviderBase extends AlbumProvider {
  const AlbumProviderBase({
    this.latestItemTime,
  });

  @override
  toString({bool isDeep = false}) {
    return "$runtimeType {"
        "latestItemTime: $latestItemTime, "
        "}";
  }

  @override
  toContentJson() {
    return {
      if (latestItemTime != null)
        "latestItemTime": latestItemTime!.toUtc().toIso8601String(),
    };
  }

  @override
  AlbumProviderBase copyWith({
    DateTime? latestItemTime,
  });

  @override
  get props => [
        latestItemTime,
      ];

  @override
  final DateTime? latestItemTime;
}

class AlbumStaticProvider extends AlbumProviderBase {
  AlbumStaticProvider({
    DateTime? latestItemTime,
    required List<AlbumItem> items,
  })  : items = UnmodifiableListView(items),
        super(
          latestItemTime: latestItemTime,
        );

  factory AlbumStaticProvider.fromJson(JsonObj json) {
    return AlbumStaticProvider(
      latestItemTime: json["latestItemTime"] == null
          ? null
          : DateTime.parse(json["latestItemTime"]),
      items: (json["items"] as List)
          .map((e) => AlbumItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  factory AlbumStaticProvider.of(Album parent) =>
      (parent.provider as AlbumStaticProvider);

  @override
  toString({bool isDeep = false}) {
    final itemsStr =
        isDeep ? items.toReadableString() : "List {length: ${items.length}}";
    return "$runtimeType {"
        "super: ${super.toString(isDeep: isDeep)}, "
        "items: $itemsStr, "
        "}";
  }

  @override
  toContentJson() {
    return {
      ...super.toContentJson(),
      "items": items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  AlbumStaticProvider copyWith({
    DateTime? latestItemTime,
    List<AlbumItem>? items,
  }) {
    return AlbumStaticProvider(
      latestItemTime: latestItemTime ?? this.latestItemTime,
      items: items ?? this.items,
    );
  }

  @override
  get props => [
        ...super.props,
        items,
      ];

  /// Immutable list of items. Modifying the list will result in an error
  final List<AlbumItem> items;

  static const _type = "static";
}

abstract class AlbumDynamicProvider extends AlbumProviderBase {
  const AlbumDynamicProvider({
    DateTime? latestItemTime,
  }) : super(latestItemTime: latestItemTime);
}

class AlbumDirProvider extends AlbumDynamicProvider {
  const AlbumDirProvider({
    required this.dirs,
    DateTime? latestItemTime,
  }) : super(
          latestItemTime: latestItemTime,
        );

  factory AlbumDirProvider.fromJson(JsonObj json) {
    return AlbumDirProvider(
      latestItemTime: json["latestItemTime"] == null
          ? null
          : DateTime.parse(json["latestItemTime"]),
      dirs: (json["dirs"] as List)
          .map((e) => File.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  toString({bool isDeep = false}) {
    return "$runtimeType {"
        "super: ${super.toString(isDeep: isDeep)}, "
        "dirs: ${dirs.map((e) => e.path).toReadableString()}, "
        "}";
  }

  @override
  toContentJson() {
    return {
      ...super.toContentJson(),
      "dirs": dirs.map((e) => e.toJson()).toList(),
    };
  }

  @override
  AlbumDirProvider copyWith({
    DateTime? latestItemTime,
    List<File>? dirs,
  }) {
    return AlbumDirProvider(
      latestItemTime: latestItemTime ?? this.latestItemTime,
      dirs: dirs ?? this.dirs,
    );
  }

  @override
  get props => [
        ...super.props,
        dirs,
      ];

  final List<File> dirs;

  static const _type = "dir";
}
