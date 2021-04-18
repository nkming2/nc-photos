extension ListExtension<T> on List<T> {
  /// Return a new list with only distinct elements
  List<T> distinct() {
    final s = Set();
    return this.where((element) => s.add(element)).toList();
  }

  /// Return a new list with only distinct elements determined by [equalFn]
  List<T> distinctIf(
      bool Function(T a, T b) equalFn, int Function(T a) hashCodeFn) {
    final s = Set<_DistinctComparator<T>>();
    return this
        .where((element) =>
            s.add(_DistinctComparator<T>(element, equalFn, hashCodeFn)))
        .toList();
  }

  Iterable<T> takeIndex(List<int> indexes) => indexes.map((e) => this[e]);
}

class _DistinctComparator<T> {
  _DistinctComparator(this.obj, this.equalFn, this.hashCodeFn);

  @override
  operator ==(Object other) =>
      other is _DistinctComparator<T> && equalFn(obj, other.obj);

  @override
  get hashCode => hashCodeFn(obj);

  final T obj;
  final bool Function(T, T) equalFn;
  final int Function(T) hashCodeFn;
}
