extension StreamExtension<T> on Stream<T> {
  Stream<U> whereType<U>() => where((event) => event is U).cast<U>();
}
