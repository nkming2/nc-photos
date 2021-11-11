extension ObjectExtension<T> on T {
  T apply(void Function(T obj) fn) {
    fn(this);
    return this;
  }
}
