import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/connectivity_util.dart' as connectivity_util;
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/metadata_task_manager.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/load_metadata.dart';
import 'package:nc_photos/use_case/scan_missing_metadata.dart';
import 'package:nc_photos/use_case/update_property.dart';

class UpdateMissingMetadata {
  UpdateMissingMetadata(this.fileRepo);

  /// Update metadata for all files that support one under a dir recursively
  ///
  /// Dirs with a .nomedia/.noimage file will be ignored. The returned stream
  /// would emit either File data (for each updated files) or an exception
  Stream<dynamic> call(Account account, File root) async* {
    final dataStream = ScanMissingMetadata(fileRepo)(account, root);
    await for (final d in dataStream) {
      if (d is Exception || d is Error) {
        yield d;
        continue;
      }
      final File file = d;
      // check if this is a federation share. Nextcloud doesn't support
      // properties for such files
      if (file.ownerId?.contains("/") == true) {
        continue;
      }
      try {
        // since we need to download multiple images in their original size,
        // we only do it with WiFi
        await connectivity_util.waitUntilWifi(onNoWifi: () {
          KiwiContainer().resolve<EventBus>().fire(
              MetadataTaskStateChangedEvent(MetadataTaskState.waitingForWifi));
        });
        KiwiContainer()
            .resolve<EventBus>()
            .fire(MetadataTaskStateChangedEvent(MetadataTaskState.prcoessing));
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

        final updateOp = UpdateProperty(FileRepo(FileCachedDataSource()));
        await updateOp(
          account,
          file,
          metadata: OrNull(metadataObj),
        );
        yield file;
      } catch (e, stacktrace) {
        _log.severe("[call] Failed while updating metadata: ${file.path}", e,
            stacktrace);
        yield e;
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
