import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/string_extension.dart';
import 'package:path/path.dart' as path_lib;

bool isSupportedMime(String mime) => _supportedFormatMimes.contains(mime);

bool isSupportedFormat(File file) => isSupportedMime(file.contentType ?? "");

bool isSupportedImageMime(String mime) =>
    isSupportedMime(mime) && mime.startsWith("image/") == true;

bool isSupportedImageFormat(File file) =>
    isSupportedImageMime(file.contentType ?? "");

bool isSupportedVideoFormat(File file) =>
    isSupportedFormat(file) && file.contentType?.startsWith("video/") == true;

bool isMetadataSupportedMime(String mime) =>
    _metadataSupportedFormatMimes.contains(mime);

bool isMetadataSupportedFormat(File file) =>
    isMetadataSupportedMime(file.contentType ?? "");

bool isTrash(Account account, File file) =>
    file.path.startsWith(api_util.getTrashbinPath(account));

bool isAlbumFile(Account account, File file) =>
    file.path.startsWith(remote_storage_util.getRemoteAlbumsDir(account));

/// Return if [file] is located under [dir]
///
/// Return false if [file] is [dir] itself (since it's not "under")
///
/// See [isOrUnderDir]
bool isUnderDir(File file, File dir) => file.path.startsWith("${dir.path}/");

/// Return if [file] is [dir] or located under [dir]
///
/// See [isUnderDir]
bool isOrUnderDir(File file, File dir) =>
    file.path == dir.path || isUnderDir(file, dir);

/// Convert a stripped path to a full path
///
/// See [File.strippedPath]
String unstripPath(Account account, String strippedPath) {
  final p = strippedPath == "." ? "" : strippedPath;
  return "${api_util.getWebdavRootUrlRelative(account)}/$p".trimRightAny("/");
}

/// For a path "remote.php/dav/files/foo/bar.jpg", return foo
CiString getUserDirName(File file) {
  if (file.path.startsWith("remote.php/dav/files/")) {
    const beg = "remote.php/dav/files/".length;
    final end = file.path.indexOf("/", beg);
    if (end != -1) {
      return file.path.substring(beg, end).toCi();
    }
  }
  throw ArgumentError("Invalid path: ${file.path}");
}

String renameConflict(String filename, int conflictCount) {
  final temp =
      "${path_lib.basenameWithoutExtension(filename)} ($conflictCount)";
  if (path_lib.extension(filename).isEmpty) {
    return temp;
  } else {
    return "$temp${path_lib.extension(filename)}";
  }
}

/// Return if this file is the no media marker
///
/// A no media marker marks the parent dir and its sub dirs as not containing
/// media files of interest
bool isNoMediaMarker(File file) => isNoMediaMarkerPath(file.path);

/// See [isNoMediaMarker]
bool isNoMediaMarkerPath(String path) {
  final filename = path_lib.basename(path);
  return filename == ".nomedia" || filename == ".noimage";
}

/// Return if there's missing metadata in [file]
///
/// Current this function will check both [File.metadata] and [File.location]
bool isMissingMetadata(File file) =>
    isSupportedImageFormat(file) &&
    (file.metadata == null || file.location == null);

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
