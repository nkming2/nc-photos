import 'dart:async';

extension ObjectExtension<T> on T {
  /// Run [fn] with this, and return this
  T apply(void Function(T obj) fn) {
    fn(this);
    return this;
  }

  /// Run [fn] with this, and return this
  Future<T> applyFuture(FutureOr<void> Function(T obj) fn) async {
    await fn(this);
    return this;
  }

  /// Run [fn] with this, and return the results of [fn]
  U run<U>(U Function(T obj) fn) => fn(this);
}
