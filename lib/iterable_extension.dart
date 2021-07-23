import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

extension IterableExtension<T> on Iterable<T> {
  /// Return a new sorted list
  List<T> sorted([int compare(T a, T b)?]) => this.toList()..sort(compare);

  /// Return a new stable sorted list
  List<T> stableSorted([int compare(T a, T b)?]) {
    final tmp = this.toList();
    mergeSort(tmp, compare: compare);
    return tmp;
  }

  /// Return a string representation of this iterable by joining the result of
  /// toString for each items
  String toReadableString() => "[${join(', ')}]";

  Iterable<U> mapWithIndex<U>(U fn(int index, T element)) sync* {
    int i = 0;
    for (final e in this) {
      yield fn(i++, e);
    }
  }

  Iterable<Tuple2<int, T>> withIndex() => mapWithIndex((i, e) => Tuple2(i, e));

  /// Whether the collection contains an element equal to [element] using the
  /// equality function [equalFn]
  bool containsIf(T element, bool Function(T a, T b) equalFn) =>
      any((e) => equalFn(e, element));

  /// Same as [contains] but uses [identical] to compare the objects
  bool containsIdentical(T element) =>
      containsIf(element, (a, b) => identical(a, b));
}
