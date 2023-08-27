import 'package:np_platform_lock/src/raw_lock.dart';
import 'package:synchronized/synchronized.dart';

class RawLock implements RawLockInterface {
  RawLock._();

  factory RawLock() => _inst;

  @override
  Future<T> synchronized<T>(int lockId, Future<T> Function() fn) =>
      (_locks[lockId] ??= Lock(reentrant: true)).synchronized(fn);

  @override
  Future<void> forceUnlock(int lockId) => Future.value();

  static final _inst = RawLock._();

  final _locks = <int, Lock>{};
}
