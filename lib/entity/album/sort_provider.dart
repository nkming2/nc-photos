import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:tuple/tuple.dart';

abstract class AlbumSortProvider with EquatableMixin {
  const AlbumSortProvider();

  factory AlbumSortProvider.fromJson(Map<String, dynamic> json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumNullSortProvider._type:
        return AlbumNullSortProvider.fromJson(content.cast<String, dynamic>());
      case AlbumTimeSortProvider._type:
        return AlbumTimeSortProvider.fromJson(content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  Map<String, dynamic> toJson() {
    String getType() {
      if (this is AlbumNullSortProvider) {
        return AlbumNullSortProvider._type;
      } else if (this is AlbumTimeSortProvider) {
        return AlbumTimeSortProvider._type;
      } else {
        throw StateError("Unknwon subtype");
      }
    }

    return {
      "type": getType(),
      "content": _toContentJson(),
    };
  }

  /// Return a sorted copy of [items]
  List<AlbumItem> sort(List<AlbumItem> items);

  Map<String, dynamic> _toContentJson();

  static final _log = Logger("entity.album.sort_provider.AlbumSortProvider");
}

/// Sort provider that does nothing
class AlbumNullSortProvider extends AlbumSortProvider {
  const AlbumNullSortProvider();

  factory AlbumNullSortProvider.fromJson(Map<String, dynamic> json) {
    return AlbumNullSortProvider();
  }

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }

  @override
  sort(List<AlbumItem> items) {
    return List.from(items);
  }

  @override
  get props => [];

  @override
  _toContentJson() {
    return {};
  }

  static const _type = "null";
}

abstract class AlbumReversibleSortProvider extends AlbumSortProvider {
  const AlbumReversibleSortProvider({
    @required this.isAscending,
  });

  @override
  toString() {
    return "$runtimeType {"
        "isAscending: $isAscending, "
        "}";
  }

  @override
  get props => [
        isAscending,
      ];

  @override
  _toContentJson() {
    return {
      "isAscending": isAscending,
    };
  }

  final bool isAscending;
}

/// Sort based on the time of the files
class AlbumTimeSortProvider extends AlbumReversibleSortProvider {
  const AlbumTimeSortProvider({
    bool isAscending,
  }) : super(isAscending: isAscending);

  factory AlbumTimeSortProvider.fromJson(Map<String, dynamic> json) {
    return AlbumTimeSortProvider(
      isAscending: json["isAscending"] ?? true,
    );
  }

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "}";
  }

  @override
  sort(List<AlbumItem> items) {
    DateTime prevFileTime;
    return items
        .map((e) {
          if (e is AlbumFileItem) {
            // take the file time
            prevFileTime = e.file.bestDateTime;
          }
          // for non file items, use the sibling file's time
          return Tuple2(
              prevFileTime ?? DateTime.fromMillisecondsSinceEpoch(0), e);
        })
        .stableSorted((x, y) {
          if (isAscending) {
            return x.item1.compareTo(y.item1);
          } else {
            return y.item1.compareTo(x.item1);
          }
        })
        .map((e) => e.item2)
        .toList();
  }

  static const _type = "time";
}
