import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/connectivity_util.dart' as connectivity_util;
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/load_metadata.dart';
import 'package:nc_photos/use_case/scan_missing_metadata.dart';
import 'package:nc_photos/use_case/update_property.dart';

class UpdateMissingMetadata {
  UpdateMissingMetadata(this.fileRepo);

  /// Update metadata for all files that support one under a dir
  ///
  /// Dirs with a .nomedia/.noimage file will be ignored. The returned stream
  /// would emit either File data (for each updated files) or ExceptionEvent
  ///
  /// If [isRecursive] is true, [root] and its sub dirs will be scanned,
  /// otherwise only [root] will be scanned. Default to true
  ///
  /// [filter] can be used to filter files -- return true if a file should be
  /// included. If [filter] is null, all files will be included.
  Stream<dynamic> call(
    Account account,
    File root, {
    bool isRecursive = true,
    bool Function(File file)? filter,
  }) async* {
    final dataStream = ScanMissingMetadata(fileRepo)(
      account,
      root,
      isRecursive: isRecursive,
    );
    await for (final d in dataStream) {
      if (d is ExceptionEvent) {
        yield d;
        continue;
      }
      final File file = d;
      // check if this is a federation share. Nextcloud doesn't support
      // properties for such files
      if (file.ownerId?.contains("/") == true || filter?.call(d) == false) {
        continue;
      }
      try {
        // since we need to download multiple images in their original size,
        // we only do it with WiFi
        await connectivity_util.waitUntilWifi(onNoWifi: () {
          KiwiContainer().resolve<EventBus>().fire(
              const MetadataTaskStateChangedEvent(
                  MetadataTaskState.waitingForWifi));
        });
        KiwiContainer().resolve<EventBus>().fire(
            const MetadataTaskStateChangedEvent(MetadataTaskState.prcoessing));
        if (!shouldRun) {
          return;
        }
        _log.fine("[call] Updating metadata for ${file.path}");
        final binary = await GetFileBinary(fileRepo)(account, file);
        final metadata = await LoadMetadata()(account, file, binary);
        int? imageWidth, imageHeight;
        Exif? exif;
        if (metadata.containsKey("resolution")) {
          imageWidth = metadata["resolution"]["width"];
          imageHeight = metadata["resolution"]["height"];
        }
        if (metadata.containsKey("exif")) {
          exif = Exif(metadata["exif"]);
        }
        final metadataObj = Metadata(
          fileEtag: file.etag,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          exif: exif,
        );

        await UpdateProperty(fileRepo)(
          account,
          file,
          metadata: OrNull(metadataObj),
        );
        yield file;
      } catch (e, stackTrace) {
        _log.severe("[call] Failed while updating metadata: ${file.path}", e,
            stackTrace);
        yield ExceptionEvent(e, stackTrace);
      }
    }
  }

  void stop() {
    shouldRun = false;
  }

  final FileRepo fileRepo;

  bool shouldRun = true;

  static final _log =
      Logger("use_case.update_missing_metadata.UpdateMissingMetadata");
}
