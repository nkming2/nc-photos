import 'dart:async';

extension ObjectExtension<T> on T {
  T apply(void Function(T obj) fn) {
    fn(this);
    return this;
  }

  Future<T> applyFuture(FutureOr<void> Function(T obj) fn) async {
    await fn(this);
    return this;
  }
}
