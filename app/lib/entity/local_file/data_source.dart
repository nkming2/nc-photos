import 'package:logging/logging.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

class LocalFileMediaStoreDataSource implements LocalFileDataSource {
  const LocalFileMediaStoreDataSource();

  @override
  listDir(String path) async {
    _log.info("[listDir] $path");
    final results = await MediaStore.queryFiles(path);
    return results
        .where((r) => file_util.isSupportedMime(r.mimeType ?? ""))
        .map(_toLocalFile)
        .toList();
  }

  static LocalFile _toLocalFile(MediaStoreQueryResult r) => LocalUriFile(
        uri: r.uri,
        displayName: r.displayName,
        path: r.path,
        lastModified: DateTime.fromMillisecondsSinceEpoch(r.dateModified),
        mime: r.mimeType,
        dateTaken: r.dateTaken?.run(DateTime.fromMillisecondsSinceEpoch),
      );

  static final _log =
      Logger("entity.local_file.data_source.LocalFileMediaStoreDataSource");
}
