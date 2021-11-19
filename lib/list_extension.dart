extension ListExtension<T> on List<T> {
  Iterable<T> takeIndex(List<int> indexes) => indexes.map((e) => this[e]);
}
