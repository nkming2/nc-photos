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

  /// Run [fn] with this, and return the results of [fn]
  Future<U> runFuture<U>(FutureOr<U> Function(T obj) fn) async {
    return await fn(this);
  }

  /// Cast this as U, or null if this is not an object of U
  U? as<U>() => this is U ? this as U : null;

  /// Return if this is contained inside [iterable]
  bool isIn(Iterable<T> iterable) => iterable.contains(this);
}
