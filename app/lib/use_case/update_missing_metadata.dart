import 'package:battery_plus/battery_plus.dart';
import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/connectivity_util.dart' as connectivity_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/load_metadata.dart';
import 'package:nc_photos/use_case/scan_missing_metadata.dart';
import 'package:nc_photos/use_case/update_property.dart';

class UpdateMissingMetadata {
  UpdateMissingMetadata(this.fileRepo);

  /// Update metadata for all files that support one under a dir
  ///
  /// The returned stream would emit either File data (for each updated files)
  /// or ExceptionEvent
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
        await ensureWifi();
        await ensureBattery();
        KiwiContainer().resolve<EventBus>().fire(
            const MetadataTaskStateChangedEvent(MetadataTaskState.prcoessing));
        if (!shouldRun) {
          return;
        }
        _log.fine("[call] Updating metadata for ${file.path}");
        final binary = await GetFileBinary(fileRepo)(account, file);
        final metadata =
            (await LoadMetadata().loadRemote(account, file, binary)).copyWith(
          fileEtag: file.etag,
        );

        await UpdateProperty(fileRepo)(
          account,
          file,
          metadata: OrNull(metadata),
        );
        yield file;

        // slow down a bit to give some space for the main isolate
        await Future.delayed(const Duration(milliseconds: 10));
      } on InterruptedException catch (_) {
        return;
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

  Future<void> ensureWifi() async {
    var count = 0;
    while (!await connectivity_util.isWifi()) {
      if (!shouldRun) {
        throw const InterruptedException();
      }
      // give a chance to reconnect with the WiFi network
      if (++count >= 12) {
        KiwiContainer().resolve<EventBus>().fire(
            const MetadataTaskStateChangedEvent(
                MetadataTaskState.waitingForWifi));
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> ensureBattery() async {
    while (await Battery().batteryLevel <= 15) {
      if (!shouldRun) {
        throw const InterruptedException();
      }
      KiwiContainer().resolve<EventBus>().fire(
          const MetadataTaskStateChangedEvent(MetadataTaskState.lowBattery));
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  final FileRepo fileRepo;

  bool shouldRun = true;

  static final _log =
      Logger("use_case.update_missing_metadata.UpdateMissingMetadata");
}
