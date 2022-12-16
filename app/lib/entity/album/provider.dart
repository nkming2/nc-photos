import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/type.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'provider.g.dart';

@npLog
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
      case AlbumTagProvider._type:
        return AlbumTagProvider.fromJson(content.cast<String, dynamic>());
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
      } else if (this is AlbumTagProvider) {
        return AlbumTagProvider._type;
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
  String toString({bool isDeep = false});

  /// Return the date time associated with the latest item, or null
  DateTime? get latestItemTime;

  AlbumProvider copyWith();

  static final _log = _$logAlbumProvider;
}

abstract class AlbumProviderBase extends AlbumProvider {
  AlbumProviderBase({
    DateTime? latestItemTime,
  }) : latestItemTime = latestItemTime?.toUtc();

  @override
  toContentJson() {
    return {
      if (latestItemTime != null)
        "latestItemTime": latestItemTime!.toUtc().toIso8601String(),
    };
  }

  @override
  AlbumProviderBase copyWith({
    OrNull<DateTime>? latestItemTime,
  });

  @override
  get props => [
        latestItemTime,
      ];

  @override
  final DateTime? latestItemTime;
}

@ToString(extraParams: r"{bool isDeep = false}")
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
  String toString({bool isDeep = false}) => _$toString(isDeep: isDeep);

  @override
  toContentJson() {
    return {
      ...super.toContentJson(),
      "items": items.map((e) => e.toJson()).toList(),
    };
  }

  @override
  AlbumStaticProvider copyWith({
    OrNull<DateTime>? latestItemTime,
    List<AlbumItem>? items,
  }) {
    return AlbumStaticProvider(
      latestItemTime:
          latestItemTime == null ? this.latestItemTime : latestItemTime.obj,
      items: items ?? List.of(this.items),
    );
  }

  @override
  get props => [
        ...super.props,
        items,
      ];

  /// Immutable list of items. Modifying the list will result in an error
  @Format(r"${isDeep ? $?.toReadableString() : '[length: ${$?.length}]'}")
  final List<AlbumItem> items;

  static const _type = "static";
}

abstract class AlbumDynamicProvider extends AlbumProviderBase {
  AlbumDynamicProvider({
    DateTime? latestItemTime,
  }) : super(latestItemTime: latestItemTime);
}

@ToString(extraParams: r"{bool isDeep = false}")
class AlbumDirProvider extends AlbumDynamicProvider {
  AlbumDirProvider({
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
  String toString({bool isDeep = false}) => _$toString(isDeep: isDeep);

  @override
  toContentJson() {
    return {
      ...super.toContentJson(),
      "dirs": dirs.map((e) => e.toJson()).toList(),
    };
  }

  @override
  AlbumDirProvider copyWith({
    OrNull<DateTime>? latestItemTime,
    List<File>? dirs,
  }) {
    return AlbumDirProvider(
      latestItemTime:
          latestItemTime == null ? this.latestItemTime : latestItemTime.obj,
      dirs: dirs ?? List.of(this.dirs),
    );
  }

  @override
  get props => [
        ...super.props,
        dirs,
      ];

  @Format(r"${$?.map((e) => e.path).toReadableString()}")
  final List<File> dirs;

  static const _type = "dir";
}

@ToString(extraParams: r"{bool isDeep = false}")
class AlbumTagProvider extends AlbumDynamicProvider {
  AlbumTagProvider({
    required this.tags,
    DateTime? latestItemTime,
  }) : super(latestItemTime: latestItemTime);

  factory AlbumTagProvider.fromJson(JsonObj json) => AlbumTagProvider(
        latestItemTime: json["latestItemTime"] == null
            ? null
            : DateTime.parse(json["latestItemTime"]),
        tags: (json["tags"] as List)
            .map((e) => Tag.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );

  @override
  String toString({bool isDeep = false}) => _$toString(isDeep: isDeep);

  @override
  toContentJson() => {
        ...super.toContentJson(),
        "tags": tags.map((t) => t.toJson()).toList(),
      };

  @override
  AlbumTagProvider copyWith({
    OrNull<DateTime>? latestItemTime,
    List<Tag>? tags,
  }) =>
      AlbumTagProvider(
        latestItemTime:
            latestItemTime == null ? this.latestItemTime : latestItemTime.obj,
        tags: tags ?? List.of(this.tags),
      );

  @override
  get props => [
        ...super.props,
        tags,
      ];

  @Format(r"${$?.map((t) => t.displayName).toReadableString()}")
  final List<Tag> tags;

  static const _type = "tag";
}

/// Smart albums are created only by the app and not the user
abstract class AlbumSmartProvider extends AlbumProviderBase {
  AlbumSmartProvider({
    DateTime? latestItemTime,
  }) : super(latestItemTime: latestItemTime);

  @override
  AlbumSmartProvider copyWith({
    OrNull<DateTime>? latestItemTime,
  }) {
    // Smart albums do not support copying
    throw UnimplementedError();
  }

  @override
  toContentJson() {
    // Smart albums do not support saving
    throw UnimplementedError();
  }
}

/// Memory album is created based on dates
@ToString(extraParams: r"{bool isDeep = false}")
class AlbumMemoryProvider extends AlbumSmartProvider {
  AlbumMemoryProvider({
    required this.year,
    required this.month,
    required this.day,
  }) : super(latestItemTime: DateTime(year, month, day));

  @override
  String toString({bool isDeep = false}) => _$toString(isDeep: isDeep);

  @override
  get props => [
        ...super.props,
        year,
        month,
        day,
      ];

  final int year;
  final int month;
  final int day;
}
