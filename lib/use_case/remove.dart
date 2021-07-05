import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/use_case/update_album.dart';

class Remove {
  Remove(this.fileRepo, this.albumRepo);

  /// Remove a file
  Future<void> call(Account account, File file) async {
    await fileRepo.remove(account, file);
    if (albumRepo != null) {
      _log.info("[call] Skip albums cleanup as albumRepo == null");
      await _cleanUpAlbums(account, file);
    }
    KiwiContainer().resolve<EventBus>().fire(FileRemovedEvent(account, file));
  }

  Future<void> _cleanUpAlbums(Account account, File file) async {
    final albums = await ListAlbum(fileRepo, albumRepo)(account);
    // clean up only make sense for static albums
    for (final a
        in albums.where((element) => element.provider is AlbumStaticProvider)) {
      try {
        final provider = AlbumStaticProvider.of(a);
        if (provider.items.any((element) =>
            element is AlbumFileItem && element.file.path == file.path)) {
          final newItems = provider.items.where((element) {
            if (element is AlbumFileItem) {
              return element.file.path != file.path;
            } else {
              return true;
            }
          }).toList();
          await UpdateAlbum(albumRepo)(
              account,
              a.copyWith(
                provider: AlbumStaticProvider(
                  items: newItems,
                ),
              ));
        }
      } catch (e, stacktrace) {
        _log.shout(
            "[_cleanUpAlbums] Failed while updating album", e, stacktrace);
        // continue to next album
      }
    }
  }

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;

  static final _log = Logger("use_case.remove.Remove");
}
