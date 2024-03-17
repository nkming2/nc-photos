extension SetExtension<T> on Set<T> {
  Set<T> added(T element) => toSet()..add(element);

  Set<T> removed(T element) => toSet()..remove(element);
}
