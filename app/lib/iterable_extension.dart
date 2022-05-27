import 'dart:async';

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

  /// The current elements of this iterable modified by async function [fn].
  ///
  /// The result of [fn] will be emitted by the returned stream in the same
  /// order as this iterable.
  ///
  /// If [simultaneousFuture] > 1, [fn] will be called multiple times before
  /// awaiting their results.
  Stream<U> mapStream<U>(
    Future<U> Function(T element) fn, [
    simultaneousFuture = 1,
  ]) async* {
    final container = <Future<U>>[];
    for (final e in this) {
      container.add(fn(e));
      if (container.length >= simultaneousFuture) {
        for (final result in await Future.wait(container)) {
          yield result;
        }
        container.clear();
      }
    }
    if (container.isNotEmpty) {
      for (final result in await Future.wait(container)) {
        yield result;
      }
    }
  }

  /// Invokes async function [fn] on each element of this iterable in iteration
  /// order.
  ///
  /// If [simultaneousFuture] > 1, [fn] will be called multiple times before
  /// awaiting their results.
  Future<void> forEachAsync(
    Future Function(T element) fn, [
    simultaneousFuture = 1,
  ]) async {
    final container = <Future>[];
    for (final e in this) {
      container.add(fn(e));
      if (container.length >= simultaneousFuture) {
        await Future.wait(container);
        container.clear();
      }
    }
    if (container.isNotEmpty) {
      await Future.wait(container);
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

  /// Invokes [action] on each element of this iterable in iteration order
  /// lazily
  Iterable<T> forEachLazy(void Function(T element) action) sync* {
    for (final e in this) {
      action(e);
      yield e;
    }
  }
}
