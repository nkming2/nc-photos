import 'package:logging/logging.dart';
import 'package:nc_photos/date_time_extension.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';

class DateGroupHelper {
  DateGroupHelper({
    required this.isMonthOnly,
  });

  DateTime? onFile(File file) {
    final newDate = file.bestDateTime.toLocal();
    if (newDate.year != _currentDate?.year ||
        newDate.month != _currentDate?.month ||
        (!isMonthOnly && newDate.day != _currentDate?.day)) {
      _currentDate = newDate;
      return newDate;
    }
  }

  final bool isMonthOnly;
  DateTime? _currentDate;
}

/// Build memory album from files
///
/// Feb 29 is treated as Mar 1 on non leap years
class MemoryAlbumHelper {
  MemoryAlbumHelper([DateTime? today])
      : today = (today?.toLocal() ?? DateTime.now()).toMidnight();

  void addFile(File f) {
    final date = f.bestDateTime.toLocal().toMidnight();
    final diff = today.difference(date).inDays;
    if (diff < 300) {
      return;
    }
    for (final dy in [0, -1, 1]) {
      if (today.copyWith(year: date.year + dy).difference(date).abs().inDays <=
          2) {
        _log.fine(
            "[addFile] Add file (${f.bestDateTime}) to ${date.year + dy}");
        _addFileToYear(f, date.year + dy);
        break;
      }
    }
  }

  /// Build list of memory albums
  ///
  /// [nameBuilder] is a function that return the name of the album for a
  /// particular year
  List<Album> build(String Function(int year) nameBuilder) {
    return _data.entries
        .sorted((a, b) => b.key.compareTo(a.key))
        .map((e) => Album(
              name: nameBuilder(e.key),
              provider: AlbumMemoryProvider(
                  year: e.key, month: today.month, day: today.day),
              coverProvider:
                  AlbumManualCoverProvider(coverFile: e.value.coverFile),
              sortProvider: const AlbumTimeSortProvider(isAscending: false),
            ))
        .toList();
  }

  void _addFileToYear(File f, int year) {
    final item = _data[year];
    final date = today.copyWith(year: year);
    if (item == null) {
      _data[year] = _MemoryAlbumHelperItem(date, f);
    } else {
      final coverDiff = _MemoryAlbumHelperItem.getCoverDiff(date, f);
      if (coverDiff < item.coverDiff) {
        item.coverFile = f;
        item.coverDiff = coverDiff;
      }
    }
  }

  final DateTime today;
  final _data = <int, _MemoryAlbumHelperItem>{};

  static final _log = Logger("widget.photo_list_util.MemoryAlbumHelper");
}

int getThumbSize(int zoomLevel) {
  switch (zoomLevel) {
    case -1:
      return 96;

    case 1:
      return 176;

    case 2:
      return 256;

    case 0:
    default:
      return 112;
  }
}

class _MemoryAlbumHelperItem {
  _MemoryAlbumHelperItem(this.date, this.coverFile)
      : coverDiff = getCoverDiff(date, coverFile);

  static Duration getCoverDiff(DateTime date, File f) =>
      f.bestDateTime.difference(date.copyWith(hour: 12)).abs();

  final DateTime date;
  File coverFile;
  Duration coverDiff;
}
