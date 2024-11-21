import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/db/entity_converter.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/service/service.dart' as service;
import 'package:np_codegen/np_codegen.dart';

part 'metadata_controller.g.dart';

@npLog
class MetadataController {
  MetadataController(
    this._c, {
    required this.account,
    required this.prefController,
  }) {
    _subscriptions
        .add(prefController.isEnableExifChange.listen(_onSetEnableExif));
  }

  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
  }

  /// Normally EXIF task only run once, call this function to make it run again
  /// after receiving new files
  void scheduleNext() {
    _hasStarted = false;
  }

  /// Kickstart the metadata task, if applicable.
  ///
  /// Running the metadata task during startup may degrade the startup time, so
  /// we are not doing so. Instead, UI code should call this function to start
  /// the task whenever it sees fit
  ///
  /// Calling this function are NOT guaranteed to actually start the task
  void kickstart() {
    _log.info("[kickstart] Metadata controller enabled");
    _isEnable = true;
    if (prefController.isEnableExifValue && !_hasStarted) {
      _startMetadataTask();
    }
  }

  void _onSetEnableExif(bool value) {
    _log.info("[_onSetEnableExif]");
    if (value) {
      if (!_isEnable) {
        _log.info("[_onSetEnableExif] Ignored as not enabled");
        return;
      }
      _startMetadataTask();
    } else {
      _stopMetadataTask();
    }
  }

  Future<void> _startMetadataTask() async {
    _hasStarted = true;
    try {
      final missingCount = await _c.npDb.countFilesByMissingMetadata(
        account: account.toDb(),
        mimes: file_util.supportedImageFormatMimes,
        ownerId: account.userId.toCaseInsensitiveString(),
      );
      _log.info("[_startMetadataTask] Missing count: $missingCount");
      if (missingCount > 0) {
        unawaited(service.startService());
      }
    } catch (e, stackTrace) {
      _log.shout(
          "[_startMetadataTask] Failed starting metadata task", e, stackTrace);
    }
  }

  void _stopMetadataTask() {
    service.stopService();
  }

  final DiContainer _c;
  final Account account;
  final PrefController prefController;

  final _subscriptions = <StreamSubscription>[];
  var _isEnable = false;
  var _hasStarted = false;
}
