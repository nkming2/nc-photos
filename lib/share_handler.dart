import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/mobile/share.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/processing_dialog.dart';
import 'package:tuple/tuple.dart';

/// Handle sharing to other apps
class ShareHandler {
  Future<void> shareFiles(
      BuildContext context, Account account, List<File> files) async {
    assert(platform_k.isAndroid);
    showDialog(
      context: context,
      builder: (context) =>
          ProcessingDialog(text: L10n.global().shareDownloadingDialogContent),
    );
    final results = <Tuple2<File, dynamic>>[];
    for (final f in files) {
      try {
        results.add(
            Tuple2(f, await platform.Downloader().downloadFile(account, f)));
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
