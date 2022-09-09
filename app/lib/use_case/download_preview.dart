import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

class DownloadPreview {
  Future<dynamic> call(Account account, File file) async {
    assert(platform_k.isAndroid);
    final previewUrl = api_util.getFilePreviewUrl(
      account,
      file,
      width: k.photoLargeSize,
      height: k.photoLargeSize,
      a: true,
    );
    final fileInfo =
        await LargeImageCacheManager.inst.getSingleFile(previewUrl, headers: {
      "authorization": Api.getAuthorizationHeaderValue(account),
    });
    return ContentUri.getUriForFile(fileInfo.absolute.path);
  }
}
