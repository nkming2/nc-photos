import 'package:collection/collection.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:tuple/tuple.dart';

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
