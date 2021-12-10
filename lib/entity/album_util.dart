import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:tuple/tuple.dart';

enum AlbumSort {
  dateDescending,
  dateAscending,
  nameAscending,
  nameDescending,
}

List<Album> sorted(List<Album> albums, AlbumSort by) {
  final isAscending = _isSortAscending(by);
  return albums
      .map<Tuple2<dynamic, Album>>((e) {
        switch (by) {
          case AlbumSort.nameAscending:
          case AlbumSort.nameDescending:
            return Tuple2(e.name, e);

          case AlbumSort.dateAscending:
          case AlbumSort.dateDescending:
            return Tuple2(e.provider.latestItemTime ?? e.lastUpdated, e);
        }
      })
      .sorted((a, b) {
        final x = isAscending ? a : b;
        final y = isAscending ? b : a;
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

bool _isSortAscending(AlbumSort sort) =>
    sort == AlbumSort.dateAscending || sort == AlbumSort.nameAscending;
