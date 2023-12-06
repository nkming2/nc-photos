import 'package:nc_photos/account.dart';
import 'package:nc_photos/db/entity_converter.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;

class ScanDirOffline {
  const ScanDirOffline(this._c);

  Future<List<FileDescriptor>> call(
    Account account,
    File root, {
    bool isOnlySupportedFormat = true,
  }) async {
    final results = await _c.npDb.getFileDescriptors(
      account: account.toDb(),
      includeRelativeRoots: [root.strippedPathWithEmpty],
      excludeRelativeRoots: [remote_storage_util.remoteStorageDirRelativePath],
      mimes: isOnlySupportedFormat ? file_util.supportedFormatMimes : null,
    );
    return results
        .map((e) =>
            DbFileDescriptorConverter.fromDb(account.userId.toString(), e))
        .toList();
  }

  final DiContainer _c;
}

class ScanDirOfflineMini {
  const ScanDirOfflineMini(this._c);

  Future<List<FileDescriptor>> call(
    Account account,
    List<File> roots,
    int limit, {
    bool isOnlySupportedFormat = true,
  }) async {
    final results = await _c.npDb.getFileDescriptors(
      account: account.toDb(),
      includeRelativeRoots: roots.map((e) => e.strippedPathWithEmpty).toList(),
      excludeRelativeRoots: [remote_storage_util.remoteStorageDirRelativePath],
      mimes: isOnlySupportedFormat ? file_util.supportedFormatMimes : null,
      limit: limit,
    );
    return results
        .map((e) =>
            DbFileDescriptorConverter.fromDb(account.userId.toString(), e))
        .toList();
  }

  final DiContainer _c;
}
