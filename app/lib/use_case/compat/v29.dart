import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Compatibility helper for v29
class CompatV29 {
  /// Clear the old cache
  static Future<void> clearDefaultCache() => DefaultCacheManager().emptyCache();
}
