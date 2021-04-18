import 'package:nc_photos/iterable_extension.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

void main() {
  group("IterableExtension", () {
    test("sorted", () {
      final src = [1, 4, 5, 2, 3, 8, 6, 7];
      expect(src.sorted(), [1, 2, 3, 4, 5, 6, 7, 8]);
    });

    test("mapWithIndex", () {
      final src = [1, 4, 5, 2, 3];
      final result =
          src.mapWithIndex((index, element) => Tuple2(index, element)).toList();
      expect(result[0], Tuple2(0, 1));
      expect(result[1], Tuple2(1, 4));
      expect(result[2], Tuple2(2, 5));
      expect(result[3], Tuple2(3, 2));
      expect(result[4], Tuple2(4, 3));
    });

    test("containsIf", () {
      final src = [
        _ContainsIfTest(1),
        _ContainsIfTest(4),
        _ContainsIfTest(5),
        _ContainsIfTest(2),
        _ContainsIfTest(3),
      ];
      expect(src.containsIf(_ContainsIfTest(5), (a, b) => a.x == b.x), true);
    });
  });
}

class _ContainsIfTest {
  _ContainsIfTest(this.x);

  final int x;
}
