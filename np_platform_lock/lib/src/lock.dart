import 'package:np_platform_lock/src/raw_lock.dart';

class PlatformLock {
  static Future<T> synchronized<T>(int lockId, Future<T> Function() fn) =>
      RawLockInterface().synchronized(lockId, fn);

  static Future<void> forceUnlock(int lockId) =>
      RawLockInterface().forceUnlock(lockId);
}
