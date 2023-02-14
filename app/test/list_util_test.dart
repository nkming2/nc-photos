import 'package:nc_photos/list_util.dart' as list_util;
import 'package:test/test.dart';

void main() {
  group("list_util", () {
    group("diff", () {
      test("extra b begin", _diffExtraBBegin);
      test("extra b end", _diffExtraBEnd);
      test("extra b mid", _diffExtraBMid);
      test("empty a", _diffAEmpty);
      test("extra a begin", _diffExtraABegin);
      test("extra a end", _diffExtraAEnd);
      test("extra a mid", _diffExtraAMid);
      test("empty b", _diffBEmpty);
      test("no matches", _diffNoMatches);
      test("repeated elements", _diffRepeatedElements);
      test("repeated elements 2", _diffRepeatedElements2);
      test("mix", _diffMix);
    });
  });
}

/// Diff with extra elements at the beginning of list b
///
/// a: [3, 4, 5]
/// b: [1, 2, 3, 4, 5]
/// Expect: [1, 2], []
void _diffExtraBBegin() {
  final diff = list_util.diff([3, 4, 5], [1, 2, 3, 4, 5]);
  expect(diff.onlyInB, [1, 2]);
  expect(diff.onlyInA, []);
}

/// Diff with extra elements at the end of list b
///
/// a: [1, 2, 3]
/// b: [1, 2, 3, 4, 5]
/// Expect: [4, 5], []
void _diffExtraBEnd() {
  final diff = list_util.diff([1, 2, 3], [1, 2, 3, 4, 5]);
  expect(diff.onlyInB, [4, 5]);
  expect(diff.onlyInA, []);
}

/// Diff with extra elements in the middle of list b
///
/// a: [1, 2, 5]
/// b: [1, 2, 3, 4, 5]
/// Expect: [3, 4], []
void _diffExtraBMid() {
  final diff = list_util.diff([1, 2, 5], [1, 2, 3, 4, 5]);
  expect(diff.onlyInB, [3, 4]);
  expect(diff.onlyInA, []);
}

/// Diff with list a being empty
///
/// a: []
/// b: [1, 2, 3]
/// Expect: [1, 2, 3], []
void _diffAEmpty() {
  final diff = list_util.diff(<int>[], [1, 2, 3]);
  expect(diff.onlyInB, [1, 2, 3]);
  expect(diff.onlyInA, []);
}

/// Diff with extra elements at the beginning of list a
///
/// a: [1, 2, 3, 4, 5]
/// b: [3, 4, 5]
/// Expect: [], [1, 2]
void _diffExtraABegin() {
  final diff = list_util.diff([1, 2, 3, 4, 5], [3, 4, 5]);
  expect(diff.onlyInB, []);
  expect(diff.onlyInA, [1, 2]);
}

/// Diff with extra elements at the end of list a
///
/// a: [1, 2, 3, 4, 5]
/// b: [1, 2, 3]
/// Expect: [], [4, 5]
void _diffExtraAEnd() {
  final diff = list_util.diff([1, 2, 3, 4, 5], [1, 2, 3]);
  expect(diff.onlyInB, []);
  expect(diff.onlyInA, [4, 5]);
}

/// Diff with extra elements in the middle of list a
///
/// a: [1, 2, 3, 4, 5]
/// b: [1, 2, 5]
/// Expect: [], [3, 4]
void _diffExtraAMid() {
  final diff = list_util.diff([1, 2, 3, 4, 5], [1, 2, 5]);
  expect(diff.onlyInB, []);
  expect(diff.onlyInA, [3, 4]);
}

/// Diff with list b being empty
///
/// a: [1, 2, 3]
/// b: []
/// Expect: [], [1, 2, 3]
void _diffBEmpty() {
  final diff = list_util.diff([1, 2, 3], <int>[]);
  expect(diff.onlyInB, []);
  expect(diff.onlyInA, [1, 2, 3]);
}

/// Diff with no matches between list a and b
///
/// a: [1, 3, 5]
/// b: [2, 4]
/// Expect: [2, 4], [1, 3, 5]
void _diffNoMatches() {
  final diff = list_util.diff([1, 3, 5], [2, 4]);
  expect(diff.onlyInB, [2, 4]);
  expect(diff.onlyInA, [1, 3, 5]);
}

/// Diff between list a and b with repeated elements
///
/// a: [1, 2, 3]
/// b: [1, 2, 2, 3]
/// Expect: [2], []
void _diffRepeatedElements() {
  final diff = list_util.diff([1, 2, 3], [1, 2, 2, 3]);
  expect(diff.onlyInB, [2]);
  expect(diff.onlyInA, []);
}

/// Diff between list a and b with repeated elements
///
/// a: [1, 3, 4, 4, 5]
/// b: [1, 2, 2, 3, 5]
/// Expect: [2, 2], [4, 4]
void _diffRepeatedElements2() {
  final diff = list_util.diff([1, 3, 4, 4, 5], [1, 2, 2, 3, 5]);
  expect(diff.onlyInB, [2, 2]);
  expect(diff.onlyInA, [4, 4]);
}

/// Diff between list a and b
///
/// a: [2, 3, 7, 10, 11, 12]
/// b: [1, 3, 4, 8, 13, 14]
/// Expect: [1, 4, 8, 13, 14], [2, 7, 10, 11, 12]
void _diffMix() {
  final diff = list_util.diff([2, 3, 7, 10, 11, 12], [1, 3, 4, 8, 13, 14]);
  expect(diff.onlyInB, [1, 4, 8, 13, 14]);
  expect(diff.onlyInA, [2, 7, 10, 11, 12]);
}
