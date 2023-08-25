import 'package:np_collection/src/iterator_extension.dart';
import 'package:test/test.dart';

void main() {
  group("iterator_extension", () {
    group("IteratorExtionsion", () {
      test("iterate", () {
        final it = [1, 2, 3, 4, 5].iterator;
        final result = <int>[];
        it.iterate((obj) => result.add(obj));
        expect(result, [1, 2, 3, 4, 5]);
      });

      test("toList", () {
        final it = [1, 2, 3, 4, 5].iterator;
        expect(it.toList(), [1, 2, 3, 4, 5]);
      });
    });
  });
}
