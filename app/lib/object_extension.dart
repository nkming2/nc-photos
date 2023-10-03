import 'dart:async';
import 'package:np_common/object_util.dart';

extension ObjectExtension<T> on T {
  /// Deprecated, use [also]
  T apply(void Function(T obj) fn) => also(fn);

  /// Deprecated, use [alsoFuture]
  Future<T> applyFuture(FutureOr<void> Function(T obj) fn) => alsoFuture(fn);

  /// Deprecated, use [let]
  U run<U>(U Function(T obj) fn) => let(fn);

  /// Deprecated, use [letFuture]
  Future<U> runFuture<U>(FutureOr<U> Function(T obj) fn) => letFuture(fn);
}
