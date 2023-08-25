import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/download_file.dart';
import 'package:nc_photos/use_case/download_preview.dart';
import 'package:nc_photos/widget/processing_dialog.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_collection/np_collection.dart';

part 'internal_download_handler.g.dart';

/// Download file to internal dir
@npLog
class InternalDownloadHandler {
  const InternalDownloadHandler(this.account);

  Future<Map<File, dynamic>> downloadPreviews(
      BuildContext context, List<File> files) async {
    final controller = StreamController<String>();
    unawaited(
      showDialog(
        context: context,
        builder: (context) => StreamBuilder(
          stream: controller.stream,
          builder: (context, snapshot) => ProcessingDialog(
            text: L10n.global().shareDownloadingDialogContent +
                (snapshot.hasData ? " ${snapshot.data}" : ""),
          ),
        ),
      ),
    );
    try {
      final results = <MapEntry<File, dynamic>>[];
      for (final pair in files.withIndex()) {
        final i = pair.item1, f = pair.item2;
        controller.add("($i/${files.length})");
        try {
          final dynamic uri;
          if (file_util.isSupportedImageFormat(f) &&
              f.contentType != "image/gif") {
            uri = await DownloadPreview()(account, f);
          } else {
            uri = await DownloadFile()(account, f);
          }
          results.add(MapEntry(f, uri));
        } catch (e, stacktrace) {
          _log.shout(
              "[downloadPreviews] Failed while DownloadPreview", e, stacktrace);
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(exception_util.toUserString(e)),
            duration: k.snackBarDurationNormal,
          ));
        }
      }
      return results.toMap();
    } finally {
      // dismiss the dialog
      Navigator.of(context).pop();
    }
  }

  Future<Map<File, dynamic>> downloadFiles(
      BuildContext context, List<File> files) async {
    final controller = StreamController<String>();
    unawaited(
      showDialog(
        context: context,
        builder: (context) => StreamBuilder(
          stream: controller.stream,
          builder: (context, snapshot) => ProcessingDialog(
            text: L10n.global().shareDownloadingDialogContent +
                (snapshot.hasData ? " ${snapshot.data}" : ""),
          ),
        ),
      ),
    );
    try {
      final results = <MapEntry<File, dynamic>>[];
      for (final pair in files.withIndex()) {
        final i = pair.item1, f = pair.item2;
        controller.add("($i/${files.length})");
        try {
          results.add(MapEntry(
              f,
              await DownloadFile()(
                account,
                f,
                shouldNotify: false,
              )));
        } on PermissionException catch (_) {
          _log.warning("[downloadFiles] Permission not granted");
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(L10n.global().errorNoStoragePermission),
            duration: k.snackBarDurationNormal,
          ));
          rethrow;
        } catch (e, stacktrace) {
          _log.shout(
              "[downloadFiles] Failed while downloadFile", e, stacktrace);
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(exception_util.toUserString(e)),
            duration: k.snackBarDurationNormal,
          ));
        }
      }
      return results.toMap();
    } finally {
      // dismiss the dialog
      Navigator.of(context).pop();
    }
  }

  final Account account;
}
