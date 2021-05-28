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

class UpdateProperty {
  UpdateProperty(this.fileRepo, this.albumRepo);

  Future<void> call(
    Account account,
    File file, {
    OrNull<Metadata> metadata,
    OrNull<bool> isArchived,
  }) async {
    if (metadata == null && isArchived == null) {
      // ?
      _log.warning("[call] Nothing to update");
      return;
    }

    if (metadata?.obj != null && metadata.obj.fileEtag != file.etag) {
      _log.warning(
          "[call] Metadata fileEtag mismatch with actual file's (metadata: ${metadata.obj.fileEtag}, file: ${file.etag})");
    }
    await fileRepo.updateProperty(
      account,
      file,
      metadata: metadata,
      isArchived: isArchived,
    );
    await _cleanUpAlbums(
      account,
      file,
      metadata: metadata,
      isArchived: isArchived,
    );

    int properties = 0;
    if (metadata != null) {
      properties |= FilePropertyUpdatedEvent.propMetadata;
    }
    if (isArchived != null) {
      properties |= FilePropertyUpdatedEvent.propIsArchived;
    }
    assert(properties != 0);
    KiwiContainer()
        .resolve<EventBus>()
        .fire(FilePropertyUpdatedEvent(account, file, properties));
  }

  Future<void> _cleanUpAlbums(
    Account account,
    File file, {
    OrNull<Metadata> metadata,
    OrNull<bool> isArchived,
  }) async {
    final albums = await ListAlbum(fileRepo, albumRepo)(account);
    for (final a in albums) {
      try {
        if (a.items.any((element) =>
            element is AlbumFileItem && element.file.path == file.path)) {
          final newItems = a.items.map((e) {
            if (e is AlbumFileItem && e.file.path == file.path) {
              return AlbumFileItem(
                file: e.file.copyWith(
                  metadata: metadata,
                  isArchived: isArchived,
                ),
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

  static final _log = Logger("use_case.update_property.UpdateProperty");
}

extension UpdatePropertyExtension on UpdateProperty {
  /// Convenience function to only update metadata
  ///
  /// See [UpdateProperty.call]
  Future<void> updateMetadata(Account account, File file, Metadata metadata) =>
      call(account, file, metadata: OrNull(metadata));

  /// Convenience function to only update isArchived
  ///
  /// See [UpdateProperty.call]
  Future<void> updateIsArchived(Account account, File file, bool isArchived) =>
      call(account, file, isArchived: OrNull(isArchived));
}
