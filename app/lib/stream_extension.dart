extension StreamExtension<T> on Stream<T> {
  Stream<U> whereType<U>() => where((event) => event is U).cast<U>();

  /// Creates a new stream from this stream that emits 1 element per [count]
  /// elements
  ///
  /// For a stream containing [A, B, C, D, E, F, G], return a new stream
  /// containing [A, C, E, G] when [count] == 2
  ///
  /// If [count] == 1, the returned stream is practically identical to the
  /// original stream
  Stream<T> per(int count) async* {
    assert(count > 0);
    if (count <= 1) {
      yield* this;
    } else {
      var i = 0;
      await for (final e in this) {
        if (i == 0) {
          yield e;
        }
        if (++i >= count) {
          i = 0;
        }
      }
    }
  }
}
