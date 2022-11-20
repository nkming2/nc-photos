import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:nc_photos/int_extension.dart';

extension ListExtension<T> on List<T> {
  Iterable<T> takeIndex(List<int> indexes) => indexes.map((e) => this[e]);

  List<T> slice(int start, [int? stop, int step = 1]) {
    assert(step > 0);
    if (start < 0) {
      start = math.max(length + start, 0);
    }
    if (stop != null && stop < 0) {
      stop = math.max(length + stop, 0);
    }
    if (start >= length) {
      return [];
    } else if (stop == null) {
      final sub = sublist(start);
      if (step <= 1) {
        return sub;
      } else {
        return sub.whereIndexed((index, _) => index % step == 0).toList();
      }
    } else if (start >= stop) {
      return [];
    } else {
      final sub = sublist(start, math.min(stop, length));
      if (step <= 1) {
        return sub;
      } else {
        return sub.whereIndexed((index, _) => index % step == 0).toList();
      }
    }
  }

  void stableSort([int Function(T a, T b)? compare]) {
    mergeSort(this, compare: compare);
  }

  /// In-place transform and return this
  ///
  /// Since the elements are in-place transformed, they have to share the same
  /// type
  List<T> transform(T Function(T element) fn) {
    for (final i in 0.until(length)) {
      this[i] = fn(this[i]);
    }
    return this;
  }
}
