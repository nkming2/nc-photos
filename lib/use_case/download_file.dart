import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:path/path.dart' as path;

class DownloadFile {
  /// Download [file]
  ///
  /// See [FileDownloader.downloadUrl]
  Future<dynamic> call(
    Account account,
    File file, {
    String? parentDir,
    bool? shouldNotify,
  }) {
    final downloader = platform.FileDownloader();
    final url = "${account.url}/${file.path}";
    return downloader.downloadUrl(
      url: url,
      headers: {
        "authorization": Api.getAuthorizationHeaderValue(account),
      },
      mimeType: file.contentType,
      filename: path.basename(file.path),
      parentDir: parentDir,
      shouldNotify: shouldNotify,
    );
  }
}
