import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/use_case/move.dart';

class RestoreTrashbin {
  RestoreTrashbin(this.fileRepo);

  Future<void> call(Account account, File file) async {
    await Move(fileRepo)(
      account,
      file,
      "remote.php/dav/trashbin/${account.username}/restore/${file.filename}",
      shouldOverwrite: true,
    );
    KiwiContainer()
        .resolve<EventBus>()
        .fire(FileTrashbinRestoredEvent(account, file));
  }

  final FileRepo fileRepo;
}
