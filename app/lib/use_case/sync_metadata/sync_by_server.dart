part of 'sync_metadata.dart';

/// Sync metadata using the client side logic
@npLog
class _SyncByServer {
  _SyncByServer({
    required this.account,
    required this.fileRepoRemote,
    required this.fileRepo2,
    required this.db,
    this.interrupter,
    required this.fallback,
  }) {
    interrupter?.listen((event) {
      _shouldRun = false;
    });
  }

  Future<void> init() async {
    await _geocoder.init();
  }

  Stream<File> syncFiles({
    required List<int> fileIds,
    required List<String> relativePaths,
  }) async* {
    final dirs = relativePaths.map(dirname).toSet();
    for (final dir in dirs) {
      yield* _syncDir(
        fileIds: fileIds,
        dir: File(path: file_util.unstripPath(account, dir)),
      );
    }
  }

  Stream<File> _syncDir({
    required List<int> fileIds,
    required File dir,
  }) async* {
    try {
      _log.fine("[_syncDir] Syncing dir $dir");
      final files = await fileRepoRemote.list(account, dir);
      await FileSqliteCacheUpdater(db)(account, dir, remote: files);
      final isEnableClientExif = await ServiceConfig.isEnableClientExif();
      for (final f in files.where((e) => fileIds.contains(e.fdId))) {
        File? result;
        if (!_supportedMimes.contains(f.fdMime)) {
          if (isEnableClientExif) {
            _log.info(
                "[_syncDir] File ${f.path} (mime: ${f.fdMime}) not supported by server, fallback to client");
            result = await fallback.syncOne(f);
          } else {
            _log.info(
                "[_syncDir] File ${f.path} (mime: ${f.fdMime}) not supported by server");
          }
        } else {
          if (f.metadata != null && f.location == null) {
            result = await _syncOne(f);
          }
        }
        if (result != null) {
          yield result;
        }
        if (!_shouldRun) {
          return;
        }
      }
    } catch (e, stackTrace) {
      _log.severe("[_syncDir] Failed to sync dir: $dir", e, stackTrace);
    }
  }

  Future<File?> _syncOne(File file) async {
    _log.fine("[_syncOne] Syncing ${file.path}");
    try {
      final lat = file.metadata!.exif?.gpsLatitudeDeg;
      final lng = file.metadata!.exif?.gpsLongitudeDeg;
      ImageLocation? location;
      if (lat != null && lng != null) {
        _log.fine("[_syncOne] Reverse geocoding for ${file.path}");
        final l = await _geocoder(lat, lng);
        if (l != null) {
          location = l.toImageLocation();
        }
      }
      final locationUpdate = OrNull(location ?? ImageLocation.empty());
      await UpdateProperty(fileRepo: fileRepo2)(
        account,
        file,
        metadata: OrNull(file.metadata),
        location: locationUpdate,
      );
      return file;
    } catch (e, stackTrace) {
      _log.severe("[_syncOne] Failed while updating location: ${file.path}", e,
          stackTrace);
      return null;
    }
  }

  final Account account;
  final FileRepo fileRepoRemote;
  final FileRepo2 fileRepo2;
  final NpDb db;
  final Stream<void>? interrupter;
  final _SyncByApp fallback;

  final _geocoder = ReverseGeocoder();
  var _shouldRun = true;

  static const _supportedMimes = [
    "image/jpeg",
    "image/webp",
  ];
}
