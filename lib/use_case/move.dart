import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/use_case/create_dir.dart';
import 'package:path/path.dart' as path;

class Move {
  Move(this.fileRepo);

  /// Move a file from its original location to [destination]
  Future<void> call(
    Account account,
    File file,
    String destination, {
    bool shouldCreateMissingDir = false,
  }) async {
    try {
      await fileRepo.move(account, file, destination);
    } catch (e) {
      if (e is ApiException &&
          e.response.statusCode == 409 &&
          shouldCreateMissingDir) {
        // no dir
        _log.info("[call] Auto creating parent dirs");
        await CreateDir(fileRepo)(account, path.dirname(destination));
        await fileRepo.move(account, file, destination);
      } else {
        rethrow;
      }
    }
    KiwiContainer()
        .resolve<EventBus>()
        .fire(FileMovedEvent(account, file, destination));
  }

  final FileRepo fileRepo;

  static final _log = Logger("use_case.move.Move");
}
