import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

abstract class Downloader {
  /// Download file to device
  ///
  /// The return data depends on the platform
  /// - web: null
  /// - android: Uri to the downloaded file
  Future<dynamic> downloadFile(Account account, File file);
}
