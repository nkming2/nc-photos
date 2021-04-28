import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/use_case/update_album.dart';

class UpdateMetadata {
  UpdateMetadata(this.fileRepo, this.albumRepo);

  Future<void> call(Account account, File file, Metadata metadata) async {
    if (metadata != null && metadata.fileEtag != file.etag) {
      _log.warning(
          "[call] Metadata fileEtag mismatch with actual file's (metadata: ${metadata.fileEtag}, file: ${file.etag})");
    }
    await fileRepo.updateMetadata(account, file, metadata);
    await _cleanUpAlbums(account, file, metadata);
    KiwiContainer()
        .resolve<EventBus>()
        .fire(FileMetadataUpdatedEvent(account, file));
  }

  Future<void> _cleanUpAlbums(
      Account account, File file, Metadata metadata) async {
    final albums = await ListAlbum(fileRepo, albumRepo)(account);
    for (final a in albums) {
      try {
        if (a.items.any((element) =>
            element is AlbumFileItem && element.file.path == file.path)) {
          final newItems = a.items.map((e) {
            if (e is AlbumFileItem && e.file.path == file.path) {
              return AlbumFileItem(
                file: e.file.copyWith(metadata: OrNull(metadata)),
              );
            } else {
              return e;
            }
          }).toList();
          await UpdateAlbum(albumRepo)(account, a.copyWith(items: newItems));
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

  static final _log = Logger("use_case.update_metadata.UpdateMetadata");
}
