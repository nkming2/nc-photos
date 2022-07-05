import 'package:nc_photos/iterator_extension.dart';
import 'package:tuple/tuple.dart';

/// Return the difference between two sorted lists, [a] and [b]
///
/// [a] and [b] MUST be sorted in ascending order, otherwise the result is
/// undefined.
///
/// The first returned list contains items exist in [b] but not [a], the second
/// returned list contains items exist in [a] but not [b]
Tuple2<List<T>, List<T>> diffWith<T>(
    Iterable<T> a, Iterable<T> b, int Function(T a, T b) comparator) {
  final aIt = a.iterator, bIt = b.iterator;
  final aMissing = <T>[], bMissing = <T>[];
  while (true) {
    if (!aIt.moveNext()) {
      // no more elements in a
      bIt.iterate((obj) => aMissing.add(obj));
      return Tuple2(aMissing, bMissing);
    }
    if (!bIt.moveNext()) {
      // no more elements in b
      // needed because aIt has already advanced
      bMissing.add(aIt.current);
      aIt.iterate((obj) => bMissing.add(obj));
      return Tuple2(aMissing, bMissing);
    }
    final result = _diffUntilEqual(aIt, bIt, comparator);
    aMissing.addAll(result.item1);
    bMissing.addAll(result.item2);
  }
}

Tuple2<List<T>, List<T>> diff<T extends Comparable>(
        Iterable<T> a, Iterable<T> b) =>
    diffWith(a, b, Comparable.compare);

Tuple2<List<T>, List<T>> _diffUntilEqual<T>(
    Iterator<T> aIt, Iterator<T> bIt, int Function(T a, T b) comparator) {
  final a = aIt.current, b = bIt.current;
  final diff = comparator(a, b);
  if (diff < 0) {
    // a < b
    if (!aIt.moveNext()) {
      return Tuple2([b] + bIt.toList(), [a]);
    } else {
      final result = _diffUntilEqual(aIt, bIt, comparator);
      return Tuple2(result.item1, [a] + result.item2);
    }
  } else if (diff > 0) {
    // a > b
    if (!bIt.moveNext()) {
      return Tuple2([b], [a] + aIt.toList());
    } else {
      final result = _diffUntilEqual(aIt, bIt, comparator);
      return Tuple2([b] + result.item1, result.item2);
    }
  } else {
    // a == b
    return const Tuple2([], []);
  }
}
