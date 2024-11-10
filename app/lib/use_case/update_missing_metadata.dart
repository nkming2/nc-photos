import 'package:battery_plus/battery_plus.dart';
import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/connectivity_util.dart' as connectivity_util;
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/exif_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/geocoder_util.dart';
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:nc_photos/use_case/load_metadata.dart';
import 'package:nc_photos/use_case/scan_missing_metadata.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/or_null.dart';
import 'package:np_geocoder/np_geocoder.dart';

part 'update_missing_metadata.g.dart';

abstract class UpdateMissingMetadataConfigProvider {
  Future<bool> isWifiOnly();
}

@npLog
class UpdateMissingMetadata {
  UpdateMissingMetadata(this._c, this.configProvider, this.geocoder);

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
    final dataStream = ScanMissingMetadata(_c.fileRepo)(
      account,
      root,
      isRecursive: isRecursive,
    );
    await for (final d in dataStream) {
      if (!_shouldRun) {
        return;
      }
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
        OrNull<Metadata>? metadataUpdate;
        OrNull<ImageLocation>? locationUpdate;
        if (file.metadata == null) {
          // since we need to download multiple images in their original size,
          // we only do it with WiFi
          await _ensureWifi();
          await _ensureBattery();
          KiwiContainer().resolve<EventBus>().fire(
              const MetadataTaskStateChangedEvent(
                  MetadataTaskState.prcoessing));
          if (!_shouldRun) {
            return;
          }
          _log.fine("[call] Updating metadata for ${file.path}");
          final binary = await GetFileBinary(_c.fileRepo)(account, file);
          final metadata =
              (await LoadMetadata().loadRemote(account, file, binary)).copyWith(
            fileEtag: file.etag,
          );
          metadataUpdate = OrNull(metadata);
        } else {
          _log.finer("[call] Skip updating metadata for ${file.path}");
          KiwiContainer().resolve<EventBus>().fire(
              const MetadataTaskStateChangedEvent(
                  MetadataTaskState.prcoessing));
        }

        final lat =
            (metadataUpdate?.obj ?? file.metadata)?.exif?.gpsLatitudeDeg;
        final lng =
            (metadataUpdate?.obj ?? file.metadata)?.exif?.gpsLongitudeDeg;
        try {
          ImageLocation? location;
          if (lat != null && lng != null) {
            _log.fine("[call] Reverse geocoding for ${file.path}");
            final l = await geocoder(lat, lng);
            if (l != null) {
              location = l.toImageLocation();
            }
          }
          locationUpdate = OrNull(location ?? ImageLocation.empty());
        } catch (e, stackTrace) {
          _log.severe("[call] Failed while reverse geocoding: ${file.path}", e,
              stackTrace);
        }

        if (metadataUpdate != null || locationUpdate != null) {
          await UpdateProperty(_c)(
            account,
            file,
            metadata: metadataUpdate,
            location: locationUpdate,
          );
          yield file;
        }

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
    _shouldRun = false;
  }

  Future<void> _ensureWifi() async {
    var count = 0;
    while (await configProvider.isWifiOnly() &&
        !await connectivity_util.isWifi()) {
      if (!_shouldRun) {
        throw const InterruptedException();
      }
      // give a chance to reconnect with the WiFi network
      if (++count >= 6) {
        KiwiContainer().resolve<EventBus>().fire(
            const MetadataTaskStateChangedEvent(
                MetadataTaskState.waitingForWifi));
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> _ensureBattery() async {
    while (await Battery().batteryLevel <= 15) {
      if (!_shouldRun) {
        throw const InterruptedException();
      }
      KiwiContainer().resolve<EventBus>().fire(
          const MetadataTaskStateChangedEvent(MetadataTaskState.lowBattery));
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  final DiContainer _c;
  final UpdateMissingMetadataConfigProvider configProvider;
  final ReverseGeocoder geocoder;

  bool _shouldRun = true;
}
