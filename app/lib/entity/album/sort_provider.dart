import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/type.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';
import 'package:tuple/tuple.dart';

part 'sort_provider.g.dart';

@npLog
abstract class AlbumSortProvider with EquatableMixin {
  const AlbumSortProvider();

  factory AlbumSortProvider.fromJson(JsonObj json) {
    final type = json["type"];
    final content = json["content"];
    switch (type) {
      case AlbumNullSortProvider._type:
        return AlbumNullSortProvider.fromJson(content.cast<String, dynamic>());
      case AlbumTimeSortProvider._type:
        return AlbumTimeSortProvider.fromJson(content.cast<String, dynamic>());
      case AlbumFilenameSortProvider._type:
        return AlbumFilenameSortProvider.fromJson(
            content.cast<String, dynamic>());
      default:
        _log.shout("[fromJson] Unknown type: $type");
        throw ArgumentError.value(type, "type");
    }
  }

  JsonObj toJson() {
    String getType() {
      if (this is AlbumNullSortProvider) {
        return AlbumNullSortProvider._type;
      } else if (this is AlbumTimeSortProvider) {
        return AlbumTimeSortProvider._type;
      } else if (this is AlbumFilenameSortProvider) {
        return AlbumFilenameSortProvider._type;
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

  JsonObj _toContentJson();

  static final _log = _$AlbumSortProviderNpLog.log;
}

/// Sort provider that does nothing
@toString
class AlbumNullSortProvider extends AlbumSortProvider {
  const AlbumNullSortProvider();

  factory AlbumNullSortProvider.fromJson(JsonObj json) {
    return const AlbumNullSortProvider();
  }

  @override
  String toString() => _$toString();

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
    required this.isAscending,
  });

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
@toString
class AlbumTimeSortProvider extends AlbumReversibleSortProvider {
  const AlbumTimeSortProvider({
    required bool isAscending,
  }) : super(isAscending: isAscending);

  factory AlbumTimeSortProvider.fromJson(JsonObj json) {
    return AlbumTimeSortProvider(
      isAscending: json["isAscending"] ?? true,
    );
  }

  @override
  String toString() => _$toString();

  @override
  sort(List<AlbumItem> items) {
    DateTime? prevFileTime;
    return items
        .map((e) {
          if (e is AlbumFileItem) {
            // take the file time
            prevFileTime = e.file.bestDateTime;
          }
          // for non file items, use the sibling file's time
          return Tuple2(prevFileTime, e);
        })
        .stableSorted((x, y) {
          if (x.item1 == null && y.item1 == null) {
            return 0;
          } else if (x.item1 == null) {
            return -1;
          } else if (y.item1 == null) {
            return 1;
          } else {
            if (isAscending) {
              return x.item1!.compareTo(y.item1!);
            } else {
              return y.item1!.compareTo(x.item1!);
            }
          }
        })
        .map((e) => e.item2)
        .toList();
  }

  static const _type = "time";
}

/// Sort based on the name of the files
@toString
class AlbumFilenameSortProvider extends AlbumReversibleSortProvider {
  const AlbumFilenameSortProvider({
    required bool isAscending,
  }) : super(isAscending: isAscending);

  factory AlbumFilenameSortProvider.fromJson(JsonObj json) {
    return AlbumFilenameSortProvider(
      isAscending: json["isAscending"] ?? true,
    );
  }

  @override
  String toString() => _$toString();

  @override
  sort(List<AlbumItem> items) {
    String? prevFilename;
    return items
        .map((e) {
          if (e is AlbumFileItem) {
            // take the file name
            prevFilename = e.file.filename;
          }
          // for non file items, use the sibling file's name
          return Tuple2(prevFilename, e);
        })
        .stableSorted((x, y) {
          if (x.item1 == null && y.item1 == null) {
            return 0;
          } else if (x.item1 == null) {
            return -1;
          } else if (y.item1 == null) {
            return 1;
          } else {
            if (isAscending) {
              return compareNatural(x.item1!, y.item1!);
            } else {
              return compareNatural(y.item1!, x.item1!);
            }
          }
        })
        .map((e) => e.item2)
        .toList();
  }

  static const _type = "filename";
}
