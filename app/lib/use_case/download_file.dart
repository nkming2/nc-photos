import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/platform/download.dart';

class DownloadFile {
  /// Create a new download but don't start it yet
  Download build(
    Account account,
    FileDescriptor file, {
    String? parentDir,
    bool? shouldNotify,
  }) {
    final url = "${account.url}/${file.fdPath}";
    return platform.DownloadBuilder().build(
      url: url,
      headers: {
        "authorization": AuthUtil.fromAccount(account).toHeaderValue(),
      },
      mimeType: file.fdMime,
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
    FileDescriptor file, {
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
