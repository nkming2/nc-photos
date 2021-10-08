import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:path/path.dart' as path;

bool isSupportedMime(String mime) => _supportedFormatMimes.contains(mime);

bool isSupportedFormat(File file) => isSupportedMime(file.contentType ?? "");

bool isSupportedImageFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("image/") == true;

bool isSupportedVideoFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("video/") == true;

bool isMetadataSupportedFormat(File file) =>
    _metadataSupportedFormatMimes.contains(file.contentType);

bool isTrash(Account account, File file) =>
    file.path.startsWith(api_util.getTrashbinPath(account));

/// For a path "remote.php/dav/files/foo/bar.jpg", return foo
String getUserDirName(File file) {
  if (file.path.startsWith("remote.php/dav/files/")) {
    const beg = "remote.php/dav/files/".length;
    final end = file.path.indexOf("/", beg);
    if (end != -1) {
      return file.path.substring(beg, end);
    }
  }
  throw ArgumentError("Invalid path: ${file.path}");
}

String renameConflict(String filename, int conflictCount) {
  final temp = "${path.basenameWithoutExtension(filename)} ($conflictCount)";
  if (path.extension(filename).isEmpty) {
    return temp;
  } else {
    return "$temp${path.extension(filename)}";
  }
}

final _supportedFormatMimes = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/gif",
  "video/mp4",
  "video/quicktime",
  if (platform_k.isAndroid || platform_k.isWeb) "video/webm",
];

const _metadataSupportedFormatMimes = [
  "image/jpeg",
  "image/heic",
];
