import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/update_missing_metadata.dart';

/// Task to update metadata for missing files
class MetadataTask {
  MetadataTask(this.account, this.pref);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  Future<void> call() async {
    try {
      final shareFolder =
          File(path: file_util.unstripPath(account, pref.getShareFolderOr()));
      bool hasScanShareFolder = false;
      final fileRepo = FileRepo(FileCachedDataSource(AppDb()));
      for (final r in account.roots) {
        final dir = File(path: file_util.unstripPath(account, r));
        hasScanShareFolder |= file_util.isOrUnderDir(shareFolder, dir);
        final op = UpdateMissingMetadata(fileRepo);
        await for (final _ in op(account, dir)) {
          if (!Pref().isEnableExifOr()) {
            _log.info("[call] EXIF disabled, task ending immaturely");
            op.stop();
            return;
          }
        }
      }
      if (!hasScanShareFolder) {
        final op = UpdateMissingMetadata(fileRepo);
        await for (final _ in op(
          account,
          shareFolder,
          isRecursive: false,
          filter: (f) => f.ownerId != account.username,
        )) {
          if (!Pref().isEnableExifOr()) {
            _log.info("[call] EXIF disabled, task ending immaturely");
            op.stop();
            return;
          }
        }
      }
    } finally {
      KiwiContainer()
          .resolve<EventBus>()
          .fire(const MetadataTaskStateChangedEvent(MetadataTaskState.idle));
    }
  }

  final Account account;
  final AccountPref pref;

  static final _log = Logger("metadata_task_manager.MetadataTask");
}

/// Manage metadata tasks to run concurrently
class MetadataTaskManager {
  factory MetadataTaskManager() {
    _inst ??= MetadataTaskManager._();
    return _inst!;
  }

  MetadataTaskManager._() {
    _stateChangedListener.begin();
    _handleStream();
  }

  /// Add a task to the queue
  void addTask(MetadataTask task) {
    _log.info("[addTask] New task added: $task");
    _streamController.add(task);
  }

  MetadataTaskState get state => _currentState;

  void _onMetadataTaskStateChanged(MetadataTaskStateChangedEvent ev) {
    if (ev.state != _currentState) {
      _currentState = ev.state;
    }
  }

  void _handleStream() async {
    await for (final task in _streamController.stream) {
      if (Pref().isEnableExifOr()) {
        _log.info("[_doTask] Executing task: $task");
        await task();
      } else {
        _log.info("[_doTask] Ignoring task: $task");
      }
    }
  }

  final _streamController = StreamController<MetadataTask>.broadcast();

  var _currentState = MetadataTaskState.idle;
  late final _stateChangedListener =
      AppEventListener<MetadataTaskStateChangedEvent>(
          _onMetadataTaskStateChanged);

  static final _log = Logger("metadata_task_manager.MetadataTaskManager");

  static MetadataTaskManager? _inst;
}

enum MetadataTaskState {
  /// No work is being done
  idle,

  /// Processing images
  prcoessing,

  /// Paused on data network
  waitingForWifi,
}
