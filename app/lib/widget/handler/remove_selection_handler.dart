import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/navigation_manager.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/inflate_file_descriptor.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/widget/trashbin_browser.dart';

class RemoveSelectionHandler {
  RemoveSelectionHandler(this._c)
      : assert(require(_c)),
        assert(InflateFileDescriptor.require(_c));

  static bool require(DiContainer c) => true;

  /// Remove [selectedFiles] and return the removed count
  Future<int> call({
    required Account account,
    required List<FileDescriptor> selection,
    bool shouldCleanupAlbum = true,
    bool isRemoveOpened = false,
    bool isMoveToTrash = false,
    bool shouldShowProcessingText = true,
  }) async {
    final selectedFiles = await InflateFileDescriptor(_c)(account, selection);
    final String processingText, successText;
    final String Function(int) failureText;
    if (isRemoveOpened) {
      processingText = L10n.global().deleteProcessingNotification;
      successText = L10n.global().deleteSuccessNotification;
      failureText = (_) => L10n.global().deleteFailureNotification;
    } else {
      processingText = L10n.global()
          .deleteSelectedProcessingNotification(selectedFiles.length);
      successText = L10n.global().deleteSelectedSuccessNotification;
      failureText =
          (count) => L10n.global().deleteSelectedFailureNotification(count);
    }
    if (shouldShowProcessingText) {
      SnackBarManager().showSnackBar(
        SnackBar(
          content: Text(processingText),
          duration: k.snackBarDurationShort,
        ),
        canBeReplaced: true,
      );
    }

    var failureCount = 0;
    await Remove(KiwiContainer().resolve<DiContainer>())(
      account,
      selectedFiles,
      onRemoveFileFailed: (file, e, stackTrace) {
        _log.shout(
            "[call] Failed while removing file: ${logFilename(file.path)}",
            e,
            stackTrace);
        ++failureCount;
      },
      shouldCleanUp: shouldCleanupAlbum,
    );
    final trashAction = isMoveToTrash
        ? SnackBarAction(
            label: L10n.global().albumTrashLabel,
            onPressed: () {
              NavigationManager().getNavigator()?.pushNamed(
                  TrashbinBrowser.routeName,
                  arguments: TrashbinBrowserArguments(account));
            },
          )
        : null;
    if (failureCount == 0) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(successText),
        duration: k.snackBarDurationNormal,
        action: trashAction,
      ));
    } else {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(failureText(failureCount)),
        duration: k.snackBarDurationNormal,
        action: trashAction,
      ));
    }
    return selectedFiles.length - failureCount;
  }

  final DiContainer _c;

  static final _log =
      Logger("widget.handler.remove_selection_handler.RemoveSelectionHandler");
}
