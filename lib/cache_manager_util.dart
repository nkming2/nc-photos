import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// ignore: implementation_imports
import 'package:flutter_cache_manager/src/cache_store.dart';

class CancelableGetFile {
  CancelableGetFile(this.store);

  Future<FileInfo> getFileUntil(String key,
      {bool ignoreMemCache = false}) async {
    FileInfo product;
    while (product == null && _shouldRun) {
      product = await store.getFile(key, ignoreMemCache: ignoreMemCache);
      await Future.delayed(Duration(milliseconds: 500));
    }
    return product ?? Future.error("Interrupted");
  }

  void cancel() {
    _shouldRun = false;
  }

  bool get isGood => _shouldRun;

  final CacheStore store;

  bool _shouldRun = true;
}
