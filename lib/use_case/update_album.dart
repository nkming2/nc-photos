import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/event/event.dart';

class UpdateAlbum {
  UpdateAlbum(this.albumRepo);

  Future<void> call(Account account, Album album) async {
    final provider = album.provider;
    if (provider is AlbumStaticProvider) {
      await albumRepo.update(
        account,
        album.copyWith(
          provider: provider.copyWith(
            items: _minimizeItems(provider.items),
          ),
        ),
      );
    } else {
      await albumRepo.update(account, album);
    }
    KiwiContainer().resolve<EventBus>().fire(AlbumUpdatedEvent(account, album));
  }

  List<AlbumItem> _minimizeItems(List<AlbumItem> items) {
    return items.map((e) => e is AlbumFileItem ? e.minimize() : e).toList();
  }

  final AlbumRepo albumRepo;
}
