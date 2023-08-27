import 'package:np_platform_lock/src/native/lock.dart';
import 'package:np_platform_lock/src/raw_lock.dart';
import 'package:np_platform_lock/src/web/raw_lock.dart' as web;
import 'package:np_platform_util/np_platform_util.dart';

class RawLock implements RawLockInterface {
  RawLock._();

  factory RawLock() => _inst;

  @override
  Future<T> synchronized<T>(int lockId, Future<T> Function() fn) async {
    if (isUnitTest) {
      return _synchronizedTest(lockId, fn);
    } else {
      return _synchronized(lockId, fn);
    }
  }

  @override
  Future<void> forceUnlock(int lockId) {
    return Lock.unlock(lockId);
  }

  Future<T> _synchronized<T>(int lockId, Future<T> Function() fn) async {
    while (!await Lock.tryLock(lockId)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    try {
      return await fn();
    } finally {
      await Lock.unlock(lockId);
    }
  }

  // this is mainly used to run test cases
  Future<T> _synchronizedTest<T>(int lockId, Future<T> Function() fn) =>
      web.RawLock().synchronized(lockId, fn);

  static final _inst = RawLock._();
}
