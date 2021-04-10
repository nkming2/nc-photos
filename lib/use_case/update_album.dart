import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/event/event.dart';

class UpdateAlbum {
  UpdateAlbum(this.albumRepo);

  Future<void> call(Account account, Album album) async {
    await albumRepo.update(account, album);
    KiwiContainer().resolve<EventBus>().fire(AlbumUpdatedEvent(account, album));
  }

  final AlbumRepo albumRepo;
}
