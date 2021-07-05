import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/iterable_extension.dart';

class UpdateDynamicAlbumTime {
  /// Update the latest item time of a dynamic album with unsorted items
  ///
  /// If no updates are needed, return the same object
  Album call(Album album, List<AlbumItem> populatedItems) {
    if (album.provider is! AlbumDynamicProvider) {
      return album;
    } else {
      return _updateWithSortedFiles(
          album,
          populatedItems
              .whereType<AlbumFileItem>()
              .map((e) => e.file)
              .where((element) => file_util.isSupportedFormat(element))
              .sorted(compareFileDateTimeDescending));
    }
  }

  /// Update the latest item time of a dynamic album with pre-sorted files
  ///
  /// The album items are expected to be sorted by
  /// [compareFileDateTimeDescending], otherwise please call the unsorted
  /// version. If no updates are needed, return the same object
  Album updateWithSortedFiles(Album album, List<File> sortedFiles) {
    if (album.provider is! AlbumDynamicProvider) {
      return album;
    } else {
      return _updateWithSortedFiles(album, sortedFiles);
    }
  }

  Album _updateWithSortedFiles(Album album, List<File> sortedFiles) {
    DateTime latestItemTime;
    try {
      latestItemTime = sortedFiles.first.bestDateTime;
    } catch (_) {
      latestItemTime = null;
    }
    if (latestItemTime != album.provider.latestItemTime) {
      return album.copyWith(
        provider: (album.provider as AlbumDynamicProvider).copyWith(
          latestItemTime: latestItemTime,
        ),
      );
    }
    return album;
  }
}
