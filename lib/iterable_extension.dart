import 'package:flutter/foundation.dart';
import 'package:nc_photos/override_comparator.dart';
import 'package:tuple/tuple.dart';

extension IterableExtension<T> on Iterable<T> {
  /// Return a new sorted list
  List<T> sorted([int Function(T a, T b)? compare]) => toList()..sort(compare);

  /// Return a new stable sorted list
  List<T> stableSorted([int Function(T a, T b)? compare]) {
    final tmp = toList();
    mergeSort(tmp, compare: compare);
    return tmp;
  }

  /// Return a string representation of this iterable by joining the result of
  /// toString for each items
  String toReadableString() => "[${join(', ')}]";

  Iterable<U> mapWithIndex<U>(U Function(int index, T element) fn) sync* {
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

  Iterable<Tuple2<U, List<T>>> groupBy<U>({required U Function(T e) key}) {
    final map = fold<Map<U, List<T>>>(
        {},
        (previousValue, element) =>
            previousValue..putIfAbsent(key(element), () => []).add(element));
    return map.entries.map((e) => Tuple2(e.key, e.value));
  }

  /// Return a new list with only distinct elements
  List<T> distinct() {
    final s = <T>{};
    return where((element) => s.add(element)).toList();
  }

  /// Return a new list with only distinct elements determined by [equalFn]
  List<T> distinctIf(
      bool Function(T a, T b) equalFn, int Function(T a) hashCodeFn) {
    final s = <OverrideComparator<T>>{};
    return where((element) =>
        s.add(OverrideComparator<T>(element, equalFn, hashCodeFn))).toList();
  }
}
