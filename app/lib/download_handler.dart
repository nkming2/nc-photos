import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/download.dart';
import 'package:nc_photos/mobile/notification.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/download_file.dart';
import 'package:tuple/tuple.dart';

class DownloadHandler {
  Future<void> downloadFiles(
    Account account,
    List<File> files, {
    String? parentDir,
  }) {
    final _DownloadHandlerBase handler;
    if (platform_k.isAndroid) {
      handler = _DownlaodHandlerAndroid();
    } else {
      handler = _DownloadHandlerWeb();
    }
    return handler.downloadFiles(
      account,
      files,
      parentDir: parentDir,
    );
  }
}

abstract class _DownloadHandlerBase {
  Future<void> downloadFiles(
    Account account,
    List<File> files, {
    String? parentDir,
  });
}

class _DownlaodHandlerAndroid extends _DownloadHandlerBase {
  @override
  downloadFiles(
    Account account,
    List<File> files, {
    String? parentDir,
  }) async {
    _log.info("[downloadFiles] Downloading ${files.length} file");
    final nm = platform.NotificationManager();
    final notif = AndroidDownloadProgressNotification(
      0,
      files.length,
      currentItemTitle: files.firstOrNull?.filename,
    );
    final id = await nm.notify(notif);

    final successes = <Tuple2<File, dynamic>>[];
    StreamSubscription<DownloadCancelEvent>? subscription;
    try {
      bool isCancel = false;
      subscription = DownloadEvent.listenDownloadCancel()
        ..onData((data) {
          if (data.notificationId == id) {
            isCancel = true;
          }
        });

      int count = 0;
      for (final f in files) {
        if (isCancel == true) {
          _log.info("[downloadFiles] User canceled remaining files");
          break;
        }
        await nm.notify(notif.copyWith(
          progress: count++,
          currentItemTitle: f.filename,
          notificationId: id,
        ));

        StreamSubscription<DownloadCancelEvent>? itemSubscription;
        try {
          final download = DownloadFile().build(
            account,
            f,
            parentDir: parentDir,
            shouldNotify: false,
          );
          itemSubscription = DownloadEvent.listenDownloadCancel()
            ..onData((data) {
              if (data.notificationId == id) {
                _log.info("[downloadFiles] Cancel requested");
                download.cancel();
              }
            });
          final result = await download();
          successes.add(Tuple2(f, result));
        } on PermissionException catch (_) {
          _log.warning("[downloadFiles] Permission not granted");
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(L10n.global().errorNoStoragePermission),
            duration: k.snackBarDurationNormal,
          ));
          break;
        } on JobCanceledException catch (_) {
          _log.info("[downloadFiles] User canceled");
          break;
        } catch (e, stackTrace) {
          _log.shout(
              "[downloadFiles] Failed while DownloadFile", e, stackTrace);
          SnackBarManager().showSnackBar(SnackBar(
            content: Text("${L10n.global().downloadFailureNotification}: "
                "${exception_util.toUserString(e)}"),
            duration: k.snackBarDurationNormal,
          ));
        } finally {
          itemSubscription?.cancel();
        }
      }
    } finally {
      subscription?.cancel();
      if (successes.isNotEmpty) {
        await _onDownloadSuccessful(successes.map((e) => e.item1).toList(),
            successes.map((e) => e.item2).toList(), id);
      } else {
        await nm.dismiss(id);
      }
    }
  }

  Future<void> _onDownloadSuccessful(
      List<File> files, List<dynamic> results, int? notificationId) async {
    final nm = platform.NotificationManager();
    await nm.notify(AndroidDownloadSuccessfulNotification(
      results.cast<String>(),
      files.map((e) => e.contentType).toList(),
      notificationId: notificationId,
    ));
  }

  static final _log = Logger("download_handler._DownloadHandlerAndroid");
}

class _DownloadHandlerWeb extends _DownloadHandlerBase {
  @override
  downloadFiles(
    Account account,
    List<File> files, {
    String? parentDir,
  }) async {
    _log.info("[downloadFiles] Downloading ${files.length} file");
    var controller = SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().downloadProcessingNotification),
      duration: k.snackBarDurationShort,
    ));
    controller?.closed.whenComplete(() {
      controller = null;
    });
    int successCount = 0;
    for (final f in files) {
      try {
        await DownloadFile()(
          account,
          f,
          parentDir: parentDir,
        );
        ++successCount;
      } on PermissionException catch (_) {
        _log.warning("[downloadFiles] Permission not granted");
        controller?.close();
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().errorNoStoragePermission),
          duration: k.snackBarDurationNormal,
        ));
        break;
      } on JobCanceledException catch (_) {
        _log.info("[downloadFiles] User canceled");
        break;
      } catch (e, stackTrace) {
        _log.shout("[downloadFiles] Failed while DownloadFile", e, stackTrace);
        controller?.close();
        SnackBarManager().showSnackBar(SnackBar(
          content: Text("${L10n.global().downloadFailureNotification}: "
              "${exception_util.toUserString(e)}"),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
    if (successCount > 0) {
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().downloadSuccessNotification),
        duration: k.snackBarDurationShort,
      ));
    }
  }

  static final _log = Logger("download_handler._DownloadHandlerWeb");
}
