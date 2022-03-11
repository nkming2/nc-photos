import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/event/event.dart';

class CreateUserShare {
  const CreateUserShare(this.shareRepo);

  Future<Share> call(Account account, File file, String shareWith) async {
    final share = await shareRepo.create(account, file, shareWith);
    KiwiContainer().resolve<EventBus>().fire(ShareCreatedEvent(account, share));
    return share;
  }

  final ShareRepo shareRepo;
}

class CreateLinkShare {
  const CreateLinkShare(this.shareRepo);

  Future<Share> call(
    Account account,
    File file, {
    String? password,
  }) async {
    final share = await shareRepo.createLink(account, file, password: password);
    KiwiContainer().resolve<EventBus>().fire(ShareCreatedEvent(account, share));
    return share;
  }

  final ShareRepo shareRepo;
}
