import 'package:np_common/object_util.dart';

extension ObjectExtension<T> on T {
  /// Deprecated, use [let]
  U run<U>(U Function(T obj) fn) => let(fn);
}
