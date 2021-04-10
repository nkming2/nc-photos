import 'dart:async';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/update_missing_metadata.dart';

/// Task to update metadata for missing files
class MetadataTask {
  MetadataTask(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  Future<void> call() async {
    final fileRepo = FileRepo(FileCachedDataSource());
    for (final r in account.roots) {
      final op = UpdateMissingMetadata(fileRepo);
      await for (final _ in op(account,
          File(path: "${api_util.getWebdavRootUrlRelative(account)}/$r"))) {
        if (!Pref.inst().isEnableExif()) {
          _log.info("[call] EXIF disabled, task ending immaturely");
          op.stop();
          return;
        }
      }
    }
  }

  final Account account;

  static final _log = Logger("metadata_task_manager.MetadataTask");
}

/// Manage metadata tasks to run concurrently
class MetadataTaskManager {
  MetadataTaskManager() {
    _handleStream();
  }

  /// Add a task to the queue
  void addTask(MetadataTask task) {
    _log.info("[addTask] New task added: $task");
    _streamController.add(task);
  }

  void _handleStream() async {
    await for (final task in _streamController.stream) {
      if (Pref.inst().isEnableExif()) {
        _log.info("[_doTask] Executing task: $task");
        await task();
      } else {
        _log.info("[_doTask] Ignoring task: $task");
      }
    }
  }

  final _streamController = StreamController<MetadataTask>.broadcast();

  static final _log = Logger("metadata_task_manager.MetadataTaskManager");
}
