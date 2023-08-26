import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/web/lock.dart' as web;
import 'package:np_platform_lock/np_platform_lock.dart' as plugin;

class Lock {
  static Future<T> synchronized<T>(int lockId, Future<T> Function() fn) async {
    if (platform_k.isAndroid) {
      return _synchronizedAndroid(lockId, fn);
    } else if (platform_k.isDesktop) {
      return _synchronizedDesktop(lockId, fn);
    } else {
      throw UnimplementedError();
    }
  }

  static Future<T> _synchronizedAndroid<T>(
      int lockId, Future<T> Function() fn) async {
    while (!await plugin.Lock.tryLock(lockId)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    try {
      return await fn();
    } finally {
      await plugin.Lock.unlock(lockId);
    }
  }

  // this is mainly used to run test cases
  static Future<T> _synchronizedDesktop<T>(
          int lockId, Future<T> Function() fn) =>
      web.Lock.synchronized(lockId, fn);
}
