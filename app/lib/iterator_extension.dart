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
