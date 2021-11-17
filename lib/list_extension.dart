import 'package:nc_photos/override_comparator.dart';

extension ListExtension<T> on List<T> {
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

  Iterable<T> takeIndex(List<int> indexes) => indexes.map((e) => this[e]);
}
