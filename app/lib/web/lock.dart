import 'package:synchronized/synchronized.dart' as dart;

// Isolates are not supported on web
class Lock {
  static Future<T> synchronized<T>(int lockId, Future<T> Function() fn) =>
      (_locks[lockId] ??= dart.Lock(reentrant: true)).synchronized(fn);

  static final _locks = <int, dart.Lock>{};
}
