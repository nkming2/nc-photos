import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos_plugin/nc_photos_plugin.dart' as plugin;

class Lock {
  static Future<T> synchronized<T>(int lockId, Future<T> Function() fn) async {
    if (platform_k.isAndroid) {
      return _synchronizedAndroid(lockId, fn);
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
}
