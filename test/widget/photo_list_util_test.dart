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
      test("-4 day", _prevYear4DaysBefore);
      test("-3 day", _prevYear3DaysBefore);
      test("+4 day", _prevYear4DaysAfter);
      test("+3 day", _prevYear3DaysAfter);
    });
    group("on feb 29", () {
      test("+feb 25", _onFeb29AddFeb25);
      test("+feb 26", _onFeb29AddFeb26);
      group("non leap year", () {
        test("+mar 5", _onFeb29AddMar5);
        test("+mar 4", _onFeb29AddMar4);
      });
      group("leap year", () {
        test("+mar 4", _onFeb29AddMar4LeapYear);
        test("+mar 3", _onFeb29AddMar3LeapYear);
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
/// File: 2020-01-30
/// Expect: empty
void _prevYear4DaysBefore() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 1, 30));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2021-02-03
/// File: 2020-01-31
/// Expect: [2020]
void _prevYear3DaysBefore() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 1, 31));
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
/// File: 2020-01-30
/// Expect: empty
void _prevYear4DaysAfter() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 2, 7));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2021-02-03
/// File: 2020-01-31
/// Expect: [2020]
void _prevYear3DaysAfter() {
  final today = DateTime(2021, 2, 3);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2020, 2, 6));
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
/// File: 2019-02-25
/// Expect: empty
void _onFeb29AddFeb25() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 2, 25));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2020-02-29
/// File: 2019-02-26
/// Expect: [2019]
void _onFeb29AddFeb26() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 2, 26));
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
/// File: 2019-03-05
/// Expect: empty
void _onFeb29AddMar5() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 3, 5));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev year
///
/// Today: 2020-02-29
/// File: 2019-03-04
/// Expect: [2019]
void _onFeb29AddMar4() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2019, 3, 4));
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
/// File: 2016-03-04
/// Expect: empty
void _onFeb29AddMar4LeapYear() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2016, 3, 4));
  obj.addFile(file);
  expect(obj.build(_nameBuilder), []);
}

/// Add a file taken in the prev leap year
///
/// Today: 2020-02-29
/// File: 2016-03-03
/// Expect: [2016]
void _onFeb29AddMar3LeapYear() {
  final today = DateTime(2020, 2, 29);
  final obj = MemoryAlbumHelper(today);
  final file = util.buildJpegFile(
      path: "", fileId: 0, lastModified: DateTime.utc(2016, 3, 3));
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
