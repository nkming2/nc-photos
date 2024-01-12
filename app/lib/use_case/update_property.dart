import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/event/event.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/or_null.dart';

part 'update_property.g.dart';

@npLog
class UpdateProperty {
  const UpdateProperty(this._c);

  Future<void> call(
    Account account,
    FileDescriptor file, {
    OrNull<Metadata>? metadata,
    OrNull<bool>? isArchived,
    OrNull<DateTime>? overrideDateTime,
    bool? favorite,
    OrNull<ImageLocation>? location,
  }) async {
    if (metadata == null &&
        isArchived == null &&
        overrideDateTime == null &&
        favorite == null &&
        location == null) {
      // ?
      _log.warning("[call] Nothing to update");
      return;
    }

    await _c.fileRepo2.updateProperty(
      account,
      file,
      metadata: metadata,
      isArchived: isArchived,
      overrideDateTime: overrideDateTime,
      favorite: favorite,
      location: location,
    );

    _notify(
      account,
      file,
      metadata: metadata,
      isArchived: isArchived,
      overrideDateTime: overrideDateTime,
      favorite: favorite,
      location: location,
    );
  }

  @Deprecated("legacy")
  void _notify(
    Account account,
    FileDescriptor file, {
    OrNull<Metadata>? metadata,
    OrNull<bool>? isArchived,
    OrNull<DateTime>? overrideDateTime,
    bool? favorite,
    OrNull<ImageLocation>? location,
  }) {
    int properties = 0;
    if (metadata != null) {
      properties |= FilePropertyUpdatedEvent.propMetadata;
    }
    if (isArchived != null) {
      properties |= FilePropertyUpdatedEvent.propIsArchived;
    }
    if (overrideDateTime != null) {
      properties |= FilePropertyUpdatedEvent.propOverrideDateTime;
    }
    if (favorite != null) {
      properties |= FilePropertyUpdatedEvent.propFavorite;
    }
    if (location != null) {
      properties |= FilePropertyUpdatedEvent.propImageLocation;
    }
    assert(properties != 0);
    KiwiContainer()
        .resolve<EventBus>()
        .fire(FilePropertyUpdatedEvent(account, file, properties));
  }

  final DiContainer _c;
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

  /// Convenience function to only update overrideDateTime
  ///
  /// See [UpdateProperty.call]
  Future<void> updateOverrideDateTime(
          Account account, File file, DateTime overrideDateTime) =>
      call(account, file, overrideDateTime: OrNull(overrideDateTime));
}
