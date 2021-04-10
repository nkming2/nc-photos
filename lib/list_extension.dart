extension ListExtension<T> on List<T> {
  /// Return a new list with only distinct elements
  List<T> distinct() {
    final s = Set();
    return this.where((element) => s.add(element)).toList();
  }

  Iterable<T> takeIndex(List<int> indexes) => indexes.map((e) => this[e]);
}
