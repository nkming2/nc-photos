extension IteratorExtionsion<T> on Iterator<T> {
  void iterate(void Function(T obj) fn) {
    while (moveNext()) {
      fn(current);
    }
  }

  List<T> toList() {
    final list = <T>[];
    iterate((obj) => list.add(obj));
    return list;
  }
}

extension IteratorMapEntryExtionsion<T, U> on Iterator<MapEntry<T, U>> {
  Map<T, U> toMap() {
    final result = <T, U>{};
    iterate((obj) => result[obj.key] = obj.value);
    return result;
  }
}
