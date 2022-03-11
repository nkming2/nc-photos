import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/widget/photo_list_util.dart';
import 'package:test/test.dart';

import '../test_util.dart' as util;

void main() {
  group("MemoryAlbumHelper", () {
    test("same year", _sameYear);
    test("next year", _nextYear);
    group("prev year", () {
      test("same day", _prevYear);
      test("-3 day", _prevYear3DaysBefore);
      test("-2 day", _prevYear2DaysBefore);
      test("+3 day", _prevYear3DaysAfter);
      test("+2 day", _prevYear2DaysAfter);
    });
    group("on feb 29", () {
      test("+feb 26", _onFeb29AddFeb26);
      test("+feb 27", _onFeb29AddFeb27);
      group("non leap year", () {
        test("+mar 4", _onFeb29AddMar4);
        test("+mar 3", _onFeb29AddMar3);
      });
      group("leap year", () {
        test("+mar 3", _onFeb29AddMar3LeapYear);
        test("+mar 2", _onFeb29AddMar2LeapYear);
      });
    });
    group("on jan 1", () {
      test("+dec 31", _onJan1AddDec31);
      test("+dec 31 a year ago", _onJan1AddDec31PrevYear);
    });
    group("on dec 31", () {
      test("+jan 1", _onDec31AddJan1);
    });
  });
}

/// Add a file taken in the same year
///
/// Today: 2021-02-03
/// File: 2021-02-01
/// Expect: empty
void _sameYear() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2021, 2, 3));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the next year. This happens if the user adjusted the
/// system clock
///
/// Today: 2021-02-03
/// File: 2022-02-03
/// Expect: empty
void _nextYear() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2022, 2, 3));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2021-02-03
/// File: 2020-02-03
/// Expect: [2020]
void _prevYear() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 2, 3));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2020",
        provider:
            AlbumMemoryProvider(year: 2020, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

/// Add a file taken in the prev year
///
/// Today: 2021-02-03
/// File: 2020-01-31
/// Expect: empty
void _prevYear3DaysBefore() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 1, 31));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2021-02-03
/// File: 2020-02-01
/// Expect: [2020]
void _prevYear2DaysBefore() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 2, 1));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2020",
        provider:
            AlbumMemoryProvider(year: 2020, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

/// Add a file taken in the prev year
///
/// Today: 2021-02-03
/// File: 2020-02-06
/// Expect: empty
void _prevYear3DaysAfter() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 2, 6));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2021-02-03
/// File: 2020-02-05
/// Expect: [2020]
void _prevYear2DaysAfter() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 2, 5));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2020",
        provider:
            AlbumMemoryProvider(year: 2020, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

/// Add a file taken in the prev year
///
/// Today: 2020-02-29
/// File: 2019-02-26
/// Expect: empty
void _onFeb29AddFeb26() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 2, 26));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2020-02-29
/// File: 2019-02-27
/// Expect: [2019]
void _onFeb29AddFeb27() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 2, 27));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2019",
        provider:
            AlbumMemoryProvider(year: 2019, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

/// Add a file taken in the prev year
///
/// Today: 2020-02-29
/// File: 2019-03-04
/// Expect: empty
void _onFeb29AddMar4() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 3, 4));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2020-02-29
/// File: 2019-03-03
/// Expect: [2019]
void _onFeb29AddMar3() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 3, 3));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2019",
        provider:
            AlbumMemoryProvider(year: 2019, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

/// Add a file taken in the prev leap year
///
/// Today: 2020-02-29
/// File: 2016-03-03
/// Expect: empty
void _onFeb29AddMar3LeapYear() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2016, 3, 3));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev leap year
///
/// Today: 2020-02-29
/// File: 2016-03-02
/// Expect: [2016]
void _onFeb29AddMar2LeapYear() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2016, 3, 2));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2016",
        provider:
            AlbumMemoryProvider(year: 2016, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

/// Add a file taken around new year's day
///
/// Today: 2020-01-01
/// File: 2019-12-31
/// Expect: empty
void _onJan1AddDec31() {
  final today = DateTime(2020, 1, 1);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 12, 31));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken around new year's day
///
/// Today: 2020-01-01
/// File: 2018-12-31
/// Expect: [2019]
void _onJan1AddDec31PrevYear() {
  final today = DateTime(2020, 1, 1);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2018, 12, 31));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2019",
        provider:
            AlbumMemoryProvider(year: 2019, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

/// Add a file taken around new year's day
///
/// Today: 2020-12-31
/// File: 2020-01-01
/// Expect: [2019]
void _onDec31AddJan1() {
  final today = DateTime(2020, 12, 31);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 1, 1));
  obj.addFile(file);
  expect(
    obj
        .build(_nameBuilder)
        .map((a) => a.copyWith(lastUpdated: OrNull(DateTime(2021))))
        .toList(),
    [
      Album(
        name: "2019",
        provider:
            AlbumMemoryProvider(year: 2019, month: today.month, day: today.day),
        coverProvider: AlbumManualCoverProvider(coverFile: file),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
        lastUpdated: DateTime(2021),
      ),
    ],
  );
}

String _nameBuilder(int year) => "$year";
