import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:np_common/ci_string.dart';
import 'package:to_string/to_string.dart';
import 'package:tuple/tuple.dart';

part 'util.g.dart';

enum CollectionSort {
  dateDescending,
  dateAscending,
  nameAscending,
  nameDescending;

  bool isAscending() {
    return this == CollectionSort.dateAscending ||
        this == CollectionSort.nameAscending;
  }
}

@toString
class CollectionShare with EquatableMixin {
  const CollectionShare({
    required this.userId,
    required this.username,
  });

  @override
  String toString() => _$toString();

  @override
  List<Object?> get props => [userId, username];

  final CiString userId;
  final String username;
}

enum CollectionShareResult {
  ok,
  partial,
}

extension CollectionListExtension on Iterable<Collection> {
  List<Collection> sortedBy(CollectionSort by) {
    return map<Tuple2<Comparable, Collection>>((e) {
      switch (by) {
        case CollectionSort.nameAscending:
        case CollectionSort.nameDescending:
          return Tuple2(e.name.toLowerCase(), e);

        case CollectionSort.dateAscending:
        case CollectionSort.dateDescending:
          return Tuple2(e.contentProvider.lastModified, e);
      }
    })
        .sorted((a, b) {
          final x = by.isAscending() ? a : b;
          final y = by.isAscending() ? b : a;
          final tmp = x.item1.compareTo(y.item1);
          if (tmp != 0) {
            return tmp;
          } else {
            return x.item2.name.compareTo(y.item2.name);
          }
        })
        .map((e) => e.item2)
        .toList();
  }
}
