import 'package:nc_photos/list_extension.dart';
import 'package:quiver/core.dart';
import 'package:test/test.dart';

void main() {
  group("ListExtension", () {
    group("distinct", () {
      test("primitive", () {
        expect([1, 2, 3, 4, 5, 3, 2, 4, 6].distinct(), [1, 2, 3, 4, 5, 6]);
      });

      test("class", () {
        expect(
            [
              _DistinctTest(1, 1),
              _DistinctTest(2, 2),
              _DistinctTest(3, 3),
              _DistinctTest(4, 4),
              _DistinctTest(5, 4),
              _DistinctTest(3, 6),
              _DistinctTest(2, 2),
              _DistinctTest(4, 8),
              _DistinctTest(6, 9),
            ].distinct(),
            [
              _DistinctTest(1, 1),
              _DistinctTest(2, 2),
              _DistinctTest(3, 3),
              _DistinctTest(4, 4),
              _DistinctTest(5, 4),
              _DistinctTest(3, 6),
              _DistinctTest(4, 8),
              _DistinctTest(6, 9),
            ]);
      });
    });

    test("distinctIf", () {
      expect(
          [
            _DistinctTest(1, 1),
            _DistinctTest(2, 2),
            _DistinctTest(3, 3),
            _DistinctTest(4, 4),
            _DistinctTest(5, 5),
            _DistinctTest(3, 6),
            _DistinctTest(2, 7),
            _DistinctTest(4, 8),
            _DistinctTest(6, 9),
          ].distinctIf((a, b) => a.x == b.x, (a) => a.x),
          [
            _DistinctTest(1, 1),
            _DistinctTest(2, 2),
            _DistinctTest(3, 3),
            _DistinctTest(4, 4),
            _DistinctTest(5, 5),
            _DistinctTest(6, 9),
          ]);
    });

    test("takeIndex", () {
      expect([1, 2, 3, 4, 5, 6].takeIndex([5, 4, 3, 1, 0]), [6, 5, 4, 2, 1]);
    });
  });
}

class _DistinctTest {
  _DistinctTest(this.x, this.y);

  @override
  operator ==(Object other) =>
      other is _DistinctTest && x == other.x && y == other.y;

  @override
  get hashCode => hash2(x, y);

  @override
  toString() => "{x: $x, y: $y}";

  final int x;
  final int y;
}
