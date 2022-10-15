import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/platform/download.dart';

class DownloadFile {
  /// Create a new download but don't start it yet
  Download build(
    Account account,
    File file, {
    String? parentDir,
    bool? shouldNotify,
  }) {
    final url = "${account.url}/${file.path}";
    return platform.DownloadBuilder().build(
      url: url,
      headers: {
        "authorization": Api.getAuthorizationHeaderValue(account),
      },
      mimeType: file.contentType,
      filename: file.filename,
      parentDir: parentDir,
      shouldNotify: shouldNotify,
    );
  }

  /// Download [file]
  ///
  /// See [DownloadBuilder]
  Future<dynamic> call(
    Account account,
    File file, {
    String? parentDir,
    bool? shouldNotify,
  }) =>
      build(
        account,
        file,
        parentDir: parentDir,
        shouldNotify: shouldNotify,
      )();
}
