import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// ignore: implementation_imports
import 'package:flutter_cache_manager/src/cache_store.dart';

class CancelableGetFile {
  CancelableGetFile(this.store);

  Future<FileInfo> getFileUntil(String key,
      {bool ignoreMemCache = false}) async {
    FileInfo? product;
    while (product == null && _shouldRun) {
      product = await store.getFile(key, ignoreMemCache: ignoreMemCache);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (product == null) {
      return Future.error("Interrupted");
    } else {
      return product;
    }
  }

  void cancel() {
    _shouldRun = false;
  }

  bool get isGood => _shouldRun;

  final CacheStore store;

  bool _shouldRun = true;
}

/// Cache manager for thumbnails
///
/// Thumbnails are pretty small in file size and also critical to the scrolling
/// performance, thus a large number of them will be kept
class ThumbnailCacheManager {
  static const key = "thumbnailCache";
  static CacheManager inst = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 20000,
    ),
  );
}

/// Cache manager for large images
///
/// Large images are only loaded when explicitly opening the photos, they are
/// very large in size. Since large images are only viewed one by one (unlike
/// thumbnails), they are less critical to the overall app responsiveness
class LargeImageCacheManager {
  // used in file_paths.xml, must not change
  static const key = "largeImageCache";
  static CacheManager inst = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 1000,
    ),
  );
}

/// Cache manager for covers
///
/// Covers are larger than thumbnails but smaller than full sized photos. They
/// are used to represent a collection
class CoverCacheManager {
  static const key = "coverCache";
  static CacheManager inst = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 300,
    ),
  );
}
