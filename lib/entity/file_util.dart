import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;

bool isSupportedFormat(File file) =>
    _supportedFormatMimes.contains(file.contentType);

bool isSupportedImageFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("image/") == true;

bool isSupportedVideoFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("video/") == true;

const _supportedFormatMimes = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  // video player currently doesn't work on web
  if (!platform_k.isWeb) "video/mp4",
];
