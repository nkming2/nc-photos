import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

class DownloadPreview {
  Future<dynamic> call(Account account, FileDescriptor file) async {
    assert(platform_k.isAndroid);
    final previewUrl = api_util.getFilePreviewUrl(
      account,
      file,
      width: k.photoLargeSize,
      height: k.photoLargeSize,
      isKeepAspectRatio: true,
    );
    final fileInfo =
        await LargeImageCacheManager.inst.getSingleFile(previewUrl, headers: {
      "authorization": AuthUtil.fromAccount(account).toHeaderValue(),
    });
    return ContentUri.getUriForFile(fileInfo.absolute.path);
  }
}
