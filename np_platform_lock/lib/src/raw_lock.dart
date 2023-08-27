import 'package:np_platform_lock/src/native/raw_lock.dart'
    if (dart.library.html) 'package:np_platform_lock/src/web/raw_lock.dart';

abstract class RawLockInterface {
  factory RawLockInterface() => RawLock();

  /// Safely run [fn] with an async lock
  Future<T> synchronized<T>(int lockId, Future<T> Function() fn);

  /// Forcefully unlock an async lock
  ///
  /// This function is mostly for development use only, for example, to fix a
  /// dangling lock after hot reload. This should not be used in production code
  ///
  /// This method may not be supported by all implementations
  Future<void> forceUnlock(int lockId);
}
