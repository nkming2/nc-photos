import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/iterable_extension.dart';

abstract class AlbumProvider with EquatableMixin {
  const AlbumProvider();

  factory AlbumProvider.fromJson(Map<String, dynamic> json) {
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

  Map<String, dynamic> toJson() {
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
  Map<String, dynamic> toContentJson();

  @override
  toString({bool isDeep = false});

  /// Return the date time associated with the latest item, or null
  DateTime get latestItemTime;

  AlbumProvider copyWith();

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

  factory AlbumStaticProvider.of(Album parent) =>
      (parent.provider as AlbumStaticProvider);

  @override
  toString({bool isDeep = false}) {
    final itemsStr =
        isDeep ? items.toReadableString() : "List {length: ${items.length}}";
    return "$runtimeType {"
        "items: $itemsStr, "
        "}";
  }

  @override
  toContentJson() {
    return {
      "items": items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  AlbumStaticProvider copyWith({List<AlbumItem> items}) {
    return AlbumStaticProvider(
      items: items ?? this.items,
    );
  }

  @override
  get latestItemTime {
    try {
      return items
          .whereType<AlbumFileItem>()
          .map((e) => e.file)
          .where((element) => file_util.isSupportedFormat(element))
          .sorted(compareFileDateTimeDescending)
          .first
          .bestDateTime;
    } catch (_) {
      return null;
    }
  }

  @override
  get props => [
        items,
      ];

  /// Immutable list of items. Modifying the list will result in an error
  final List<AlbumItem> items;

  static const _type = "static";
}

abstract class AlbumDynamicProvider extends AlbumProvider {
  AlbumDynamicProvider({
    DateTime latestItemTime,
  }) : _latestItemTime = latestItemTime;

  @override
  toString({bool isDeep = false}) {
    return "$runtimeType {"
        "latestItemTime: $_latestItemTime, "
        "}";
  }

  @override
  toContentJson() {
    return {
      "latestItemTime": _latestItemTime?.toUtc()?.toIso8601String(),
    };
  }

  @override
  AlbumDynamicProvider copyWith({
    DateTime latestItemTime,
  });

  @override
  get latestItemTime => _latestItemTime;

  @override
  get props => [
        _latestItemTime,
      ];

  final DateTime _latestItemTime;
}

class AlbumDirProvider extends AlbumDynamicProvider {
  AlbumDirProvider({
    @required this.dirs,
    DateTime latestItemTime,
  }) : super(latestItemTime: latestItemTime);

  factory AlbumDirProvider.fromJson(Map<String, dynamic> json) {
    return AlbumDirProvider(
      dirs: (json["dirs"] as List)
          .map((e) => File.fromJson(e.cast<String, dynamic>()))
          .toList(),
      latestItemTime: json["latestItemTime"] == null
          ? null
          : DateTime.parse(json["latestItemTime"]),
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
    List<File> dirs,
    DateTime latestItemTime,
  }) {
    return AlbumDirProvider(
      dirs: dirs ?? this.dirs,
      latestItemTime: latestItemTime ?? this.latestItemTime,
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
