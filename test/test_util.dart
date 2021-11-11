import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';

void initLog() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
        "[${record.loggerName}] ${record.level.name}: ${record.message}");
  });
}

Account buildAccount({
  String scheme = "http",
  String address = "example.com",
  String username = "admin",
  String password = "pass",
  List<String> roots = const [""],
}) =>
    Account(scheme, address, username, password, roots);

/// Build a mock [File] pointing to a album JSON file
///
/// Warning: not all fields are filled, but the most essential ones are
File buildAlbumFile({
  required String path,
  int contentLength = 1024,
  DateTime? lastModified,
  required int fileId,
  String ownerId = "admin",
}) =>
    File(
      path: path,
      contentLength: contentLength,
      contentType: "application/json",
      lastModified: lastModified ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
      isCollection: false,
      hasPreview: false,
      fileId: fileId,
      ownerId: ownerId,
    );

String buildAlbumFilePath(
  String filename, {
  String user = "admin",
}) =>
    "remote.php/dav/files/$user/.com.nkming.nc_photos/albums/$filename";

/// Build a mock [File] pointing to a JPEG image file
///
/// Warning: not all fields are filled, but the most essential ones are
File buildJpegFile({
  required String path,
  int contentLength = 1024,
  DateTime? lastModified,
  bool hasPreview = true,
  required int fileId,
  String ownerId = "admin",
}) =>
    File(
      path: path,
      contentLength: contentLength,
      contentType: "image/jpeg",
      lastModified: lastModified ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
      isCollection: false,
      hasPreview: hasPreview,
      fileId: fileId,
      ownerId: ownerId,
    );

Share buildShare({
  required String id,
  DateTime? stime,
  String uidOwner = "admin",
  String? displaynameOwner,
  required File file,
  required String shareWith,
}) =>
    Share(
      id: id,
      shareType: ShareType.user,
      stime: stime ?? DateTime.utc(2020, 1, 2, 3, 4, 5),
      uidOwner: uidOwner,
      displaynameOwner: displaynameOwner ?? uidOwner,
      path: file.strippedPath,
      itemType: ShareItemType.file,
      mimeType: file.contentType ?? "",
      itemSource: file.fileId!,
      shareWith: shareWith,
      shareWithDisplayName: shareWith,
    );

Sharee buildSharee({
  ShareeType type = ShareeType.user,
  String label = "admin",
  int shareType = 0,
  required String shareWith,
  String? shareWithDisplayNameUnique,
}) =>
    Sharee(
      type: type,
      label: label,
      shareType: shareType,
      shareWith: shareWith,
    );
