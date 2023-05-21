import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/event/event.dart';

class CreateAlbum {
  CreateAlbum(this.albumRepo);

  Future<Album> call(Account account, Album album) async {
    final newAlbum = await albumRepo.create(account, album);
    KiwiContainer()
        .resolve<EventBus>()
        .fire(AlbumCreatedEvent(account, newAlbum));
    return newAlbum;
  }

  final AlbumRepo albumRepo;
}
