extension StreamExtension on Stream {
  Stream<U> whereType<U>() => where((event) => event is U).cast<U>();
}
