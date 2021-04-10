import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

abstract class Downloader {
  /// Download file to device
  Future<void> downloadFile(Account account, File file);
}
