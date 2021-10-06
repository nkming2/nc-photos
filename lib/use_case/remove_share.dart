import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/event/event.dart';

class RemoveShare {
  const RemoveShare(this.shareRepo);

  Future<void> call(Account account, Share share) async {
    await shareRepo.delete(account, share);
    KiwiContainer().resolve<EventBus>().fire(ShareRemovedEvent(account, share));
  }

  final ShareRepo shareRepo;
}
