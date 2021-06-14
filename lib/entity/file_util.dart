import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;

bool isSupportedFormat(File file) =>
    _supportedFormatMimes.contains(file.contentType);

bool isSupportedImageFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("image/") == true;

bool isSupportedVideoFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("video/") == true;

bool isMetadataSupportedFormat(File file) =>
    _metadataSupportedFormatMimes.contains(file.contentType);

/// For a path "remote.php/dav/files/foo/bar.jpg", return foo
String getUserDirName(File file) {
  if (file.path.startsWith("remote.php/dav/files/")) {
    final beg = "remote.php/dav/files/".length;
    final end = file.path.indexOf("/", beg);
    if (end != -1) {
      return file.path.substring(beg, end);
    }
  }
  throw ArgumentError("Invalid path: ${file.path}");
}

const _supportedFormatMimes = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  // video player currently doesn't work on web
  if (!platform_k.isWeb) "video/mp4",
];

const _metadataSupportedFormatMimes = [
  "image/jpeg",
  "image/heic",
];
