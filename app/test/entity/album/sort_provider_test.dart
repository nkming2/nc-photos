import 'package:collection/collection.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:test/test.dart';

import '../../test_util.dart' as util;

void main() {
  group("AlbumSortProvider", () {
    group("fromJson", () {
      test("AlbumTimeSortProvider", _timeFromJson);
    });
    group("toJson", () {
      test("AlbumTimeSortProvider", _timeToJson);
    });
  });

  group("AlbumTimeSortProvider", () {
    group("AlbumFileItem", () {
      test("ascending", _timeFileAscending);
      test("descending", _timeFileDescending);
    });
    group("w/ non AlbumFileItem", () {
      test("ascending", _timeNonFileAscending);
      test("descending", _timeNonFileDescending);
      test("head", _timeNonFileHead);
    });
  });

  group("AlbumFilenameSortProvider", () {
    group("AlbumFileItem", () {
      test("ascending", _filenameFileAscending);
      test("descending", _filenameFileDescending);
      test("natural", _filenameFileNatural);
    });
    group("w/ non AlbumFileItem", () {
      test("ascending", _filenameNonFileAscending);
      test("descending", _filenameNonFileDescending);
      test("head", _filenameNonFileHead);
    });
  });
}

void _timeFromJson() {
  final json = <String, dynamic>{
    "type": "time",
    "content": <String, dynamic>{
      "isAscending": false,
    },
  };
  expect(
    AlbumSortProvider.fromJson(json),
    const AlbumTimeSortProvider(isAscending: false),
  );
}

void _timeToJson() {
  expect(
    const AlbumTimeSortProvider(isAscending: false).toJson(),
    <String, dynamic>{
      "type": "time",
      "content": <String, dynamic>{
        "isAscending": false,
      },
    },
  );
}

/// Sort files by time
///
/// Expect: items sorted
void _timeFileAscending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  const sort = AlbumTimeSortProvider(isAscending: true);
  expect(sort.sort(items), [items[1], items[0], items[2]]);
}

/// Sort files by time, descending
///
/// Expect: items sorted
void _timeFileDescending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  const sort = AlbumTimeSortProvider(isAscending: false);
  expect(sort.sort(items), [items[2], items[0], items[1]]);
}

/// Sort files + non files by time
///
/// Expect: file sorted, non file stick with the prev file
void _timeNonFileAscending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed<AlbumItem>((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  items.insert(
    2,
    AlbumLabelItem(
      addedBy: CiString("admin"),
      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
      text: "test",
    ),
  );
  const sort = AlbumTimeSortProvider(isAscending: true);
  expect(sort.sort(items), [items[1], items[2], items[0], items[3]]);
}

/// Sort files + non files by time, descending
///
/// Expect: file sorted, non file stick with the prev file
void _timeNonFileDescending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed<AlbumItem>((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  items.insert(
    2,
    AlbumLabelItem(
      addedBy: CiString("admin"),
      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
      text: "test",
    ),
  );
  const sort = AlbumTimeSortProvider(isAscending: false);
  expect(sort.sort(items), [items[3], items[0], items[1], items[2]]);
}

/// Sort files + non files by time, with the head being a non file
///
/// Expect: file sorted, non file stick at the head
void _timeNonFileHead() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed<AlbumItem>((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  items.insert(
    0,
    AlbumLabelItem(
      addedBy: CiString("admin"),
      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
      text: "test",
    ),
  );
  const sort = AlbumTimeSortProvider(isAscending: true);
  expect(sort.sort(items), [items[0], items[2], items[1], items[3]]);
}

/// Sort files by filename
///
/// Expect: items sorted
void _filenameFileAscending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  const sort = AlbumFilenameSortProvider(isAscending: true);
  expect(sort.sort(items), [items[1], items[2], items[0]]);
}

/// Sort files by filename, descending
///
/// Expect: items sorted
void _filenameFileDescending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  const sort = AlbumFilenameSortProvider(isAscending: false);
  expect(sort.sort(items), [items[0], items[2], items[1]]);
}

/// Sort files by filename
///
/// Expect: items sorted in natural order
void _filenameFileNatural() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test033_2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test033_1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test033_3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test11.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        )
        ..addJpeg(
          "admin/test2_999.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        ))
      .build()
      .mapIndexed((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  const sort = AlbumFilenameSortProvider(isAscending: true);
  expect(
    sort.sort(items),
    [items[4], items[5], items[3], items[1], items[0], items[2]],
  );
}

/// Sort files + non files by filename
///
/// Expect: file sorted, non file stick with the prev file
void _filenameNonFileAscending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed<AlbumItem>((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  items.insert(
    2,
    AlbumLabelItem(
      addedBy: CiString("admin"),
      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
      text: "test",
    ),
  );
  const sort = AlbumFilenameSortProvider(isAscending: true);
  expect(sort.sort(items), [items[1], items[2], items[3], items[0]]);
}

/// Sort files + non files by filename, descending
///
/// Expect: file sorted, non file stick with the prev file
void _filenameNonFileDescending() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed<AlbumItem>((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  items.insert(
    2,
    AlbumLabelItem(
      addedBy: CiString("admin"),
      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
      text: "test",
    ),
  );
  const sort = AlbumFilenameSortProvider(isAscending: false);
  expect(sort.sort(items), [items[0], items[3], items[1], items[2]]);
}

/// Sort files + non files by filename, with the head being a non file
///
/// Expect: file sorted, non file stick at the head
void _filenameNonFileHead() {
  final items = (util.FilesBuilder()
        ..addJpeg(
          "admin/test3.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 1),
        )
        ..addJpeg(
          "admin/test1.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 0),
        )
        ..addJpeg(
          "admin/test2.jpg",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 2),
        ))
      .build()
      .mapIndexed<AlbumItem>((i, f) => AlbumFileItem(
            addedBy: CiString("admin"),
            addedAt: f.lastModified!,
            file: f,
          ))
      .toList();
  items.insert(
    0,
    AlbumLabelItem(
      addedBy: CiString("admin"),
      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5),
      text: "test",
    ),
  );
  const sort = AlbumFilenameSortProvider(isAscending: true);
  expect(sort.sort(items), [items[0], items[2], items[3], items[1]]);
}
