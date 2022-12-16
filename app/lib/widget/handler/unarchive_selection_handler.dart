import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/use_case/inflate_file_descriptor.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:np_codegen/np_codegen.dart';

part 'unarchive_selection_handler.g.dart';

@npLog
class UnarchiveSelectionHandler {
  UnarchiveSelectionHandler(this._c)
      : assert(require(_c)),
        assert(InflateFileDescriptor.require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.fileRepo);

  /// Unarchive [selectedFiles] and return the unarchived count
  Future<int> call({
    required Account account,
    required List<FileDescriptor> selection,
    bool shouldShowProcessingText = true,
  }) async {
    final selectedFiles = await InflateFileDescriptor(_c)(account, selection);
    return await NotifiedListAction<File>(
      list: selectedFiles,
      action: (file) async {
        await UpdateProperty(_c.fileRepo)
            .updateIsArchived(account, file, false);
      },
      processingText: shouldShowProcessingText
          ? L10n.global()
              .unarchiveSelectedProcessingNotification(selectedFiles.length)
          : null,
      successText: L10n.global().unarchiveSelectedSuccessNotification,
      getFailureText: (failures) =>
          L10n.global().unarchiveSelectedFailureNotification(failures.length),
      onActionError: (file, e, stackTrace) {
        _log.shout(
            "[call] Failed while unarchiving file: ${logFilename(file.path)}",
            e,
            stackTrace);
      },
    )();
  }

  final DiContainer _c;
}
