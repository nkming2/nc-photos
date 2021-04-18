extension IterableExtension<T> on Iterable<T> {
  /// Return a new sorted list
  List<T> sorted([int compare(T a, T b)]) => this.toList()..sort(compare);

  /// Return a string representation of this iterable by joining the result of
  /// toString for each items
  String toReadableString() => "[${join(', ')}]";

  Iterable<U> mapWithIndex<U>(U fn(int index, T element)) sync* {
    int i = 0;
    for (final e in this) {
      yield fn(i++, e);
    }
  }

  /// Whether the collection contains an element equal to [element] using the
  /// equality function [equalFn]
  bool containsIf(T element, bool Function(T a, T b) equalFn) =>
      any((e) => equalFn(e, element));
}
