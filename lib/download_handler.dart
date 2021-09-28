import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/notification.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/download_file.dart';
import 'package:tuple/tuple.dart';

class DownloadHandler {
  Future<void> downloadFiles(Account account, List<File> files) async {
    _log.info("[downloadFiles] Downloading ${files.length} file");
    var controller = SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().downloadProcessingNotification),
      duration: k.snackBarDurationShort,
    ));
    controller?.closed.whenComplete(() {
      controller = null;
    });
    final successes = <Tuple2<File, dynamic>>[];
    for (final f in files) {
      try {
        successes.add(Tuple2(f, await DownloadFile()(account, f)));
      } on PermissionException catch (_) {
        _log.warning("[downloadFiles] Permission not granted");
        controller?.close();
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().downloadFailureNoPermissionNotification),
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
    if (successes.isNotEmpty) {
      controller?.close();
      await _onDownloadSuccessful(successes.map((e) => e.item1).toList(),
          successes.map((e) => e.item2).toList());
    }
  }

  Future<void> _onDownloadSuccessful(
      List<File> files, List<dynamic> results) async {
    dynamic notif;
    if (platform_k.isAndroid) {
      notif = AndroidItemDownloadSuccessfulNotification(
          results.cast<String>(), files.map((e) => e.contentType).toList());
    }
    if (notif != null) {
      try {
        await notif.notify();
        return;
      } catch (e, stacktrace) {
        _log.shout(
            "[_onDownloadSuccessful] Failed showing platform notification",
            e,
            stacktrace);
      }
    }

    // fallback
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().downloadSuccessNotification),
      duration: k.snackBarDurationShort,
    ));
  }

  static final _log = Logger("download_handler.DownloadHandler");
}
