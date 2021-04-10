import 'dart:io';

import 'package:exifdart/exifdart_memory.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/image_size_getter_util.dart';
import 'package:nc_photos/platform/metadata_loader.dart' as itf;

class MetadataLoader implements itf.MetadataLoader {
  // on web we just download the image again, hopefully the browser would
  // cache it for us (which is sadly not the case :|
  @override
  loadCacheFile(Account account, File file) => loadNewFile(account, file);

  @override
  loadNewFile(Account account, File file) async {
    final response =
        await Api(account).files().get(path: api_util.getFileUrlRelative(file));
    if (!response.isGood) {
      _log.severe("[loadFile] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
    final resolution =
        await AsyncImageSizeGetter.getSize(AsyncMemoryInput(response.body));
    final exif = await readExifFromBytes(response.body);
    return {
      if (exif != null) "exif": exif,
      if (resolution.width > 0 && resolution.height > 0)
        "resolution": {
          "width": resolution.width,
          "height": resolution.height,
        },
    };
  }

  @override
  loadFile(Account account, File file) => loadNewFile(account, file);

  @override
  cancel() {}

  static final _log = Logger("web.metadata_loader.MetadataLoader");
}
