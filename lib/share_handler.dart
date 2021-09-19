import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/mobile/share.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/download_file.dart';
import 'package:nc_photos/widget/processing_dialog.dart';
import 'package:tuple/tuple.dart';

/// Handle sharing to other apps
class ShareHandler {
  Future<void> shareFiles(
      BuildContext context, Account account, List<File> files) async {
    assert(platform_k.isAndroid);
    final controller = StreamController<String>();
    showDialog(
      context: context,
      builder: (context) => StreamBuilder(
        stream: controller.stream,
        builder: (context, snapshot) => ProcessingDialog(
          text: L10n.global().shareDownloadingDialogContent +
              (snapshot.hasData ? " ${snapshot.data}" : ""),
        ),
      ),
    );
    final results = <Tuple2<File, dynamic>>[];
    for (final pair in files.withIndex()) {
      final i = pair.item1, f = pair.item2;
      controller.add("(${i + 1}/${files.length})");
      try {
        results.add(Tuple2(
            f,
            await DownloadFile()(
              account,
              f,
              shouldNotify: false,
            )));
      } on PermissionException catch (_) {
        _log.warning("[shareFiles] Permission not granted");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().downloadFailureNoPermissionNotification),
          duration: k.snackBarDurationNormal,
        ));
        // dismiss the dialog
        Navigator.of(context).pop();
        rethrow;
      } catch (e, stacktrace) {
        _log.shout("[shareFiles] Failed while downloadFile", e, stacktrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e)),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
    // dismiss the dialog
    Navigator.of(context).pop();

    final share = AndroidShare(results.map((e) => e.item2 as String).toList(),
        results.map((e) => e.item1.contentType).toList());
    share.share();
  }

  static final _log = Logger("share_handler.ShareHandler");
}
