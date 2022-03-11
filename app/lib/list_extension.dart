import 'dart:math' as math;

extension ListExtension<T> on List<T> {
  Iterable<T> takeIndex(List<int> indexes) => indexes.map((e) => this[e]);

  List<T> slice(int start, [int? stop]) {
    if (start < 0) {
      start = math.max(length + start, 0);
    }
    if (stop != null && stop < 0) {
      stop = math.max(length + stop, 0);
    }
    if (start >= length) {
      return [];
    } else if (stop == null) {
      return sublist(start);
    } else if (start >= stop) {
      return [];
    } else {
      return sublist(start, math.min(stop, length));
    }
  }
}
