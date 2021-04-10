import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

abstract class MetadataLoader {
  /// Load metadata for [file] from cache
  ///
  /// If the file is not found in cache after a certain amount of time, an
  /// exception will be thrown
  Future<Map<String, dynamic>> loadCacheFile(Account account, File file);

  /// Download and load metadata for [file]
  ///
  /// This function will always try to download the file, no matter it's cached
  /// or not
  Future<Map<String, dynamic>> loadNewFile(Account account, File file);

  /// Load metadata for [file], either from cache or a new download
  Future<Map<String, dynamic>> loadFile(Account account, File file);

  void cancel();
}
