import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/use_case/update_property.dart';

class ArchiveSelectionHandler {
  ArchiveSelectionHandler(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.fileRepo);

  /// Archive [selectedFiles] and return the archived count
  Future<int> call({
    required Account account,
    required List<File> selectedFiles,
  }) {
    return NotifiedListAction<File>(
      list: selectedFiles,
      action: (file) async {
        await UpdateProperty(_c.fileRepo).updateIsArchived(account, file, true);
      },
      processingText: L10n.global()
          .archiveSelectedProcessingNotification(selectedFiles.length),
      successText: L10n.global().archiveSelectedSuccessNotification,
      getFailureText: (failures) =>
          L10n.global().archiveSelectedFailureNotification(failures.length),
      onActionError: (file, e, stackTrace) {
        _log.shout(
            "[call] Failed while archiving file: ${logFilename(file.path)}",
            e,
            stackTrace);
      },
    )();
  }

  final DiContainer _c;

  static final _log = Logger(
      "widget.handler.archive_selection_handler.ArchiveSelectionHandler");
}
