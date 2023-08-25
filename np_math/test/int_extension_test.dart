import 'package:np_math/src/int_extension.dart';
import 'package:test/test.dart';

void main() {
  group("IntExtension", () {
    group("until", () {
      /// Expected: exception
      test("step == 0", () {
        expect(() => 1.until(10, 0), throwsArgumentError);
      });

      /// Expected: [1, ..., 9]
      test("+to > +beg, default step", () {
        expect(1.until(10).toList(), List.generate(9, (i) => i + 1));
      });

      /// Expected: [1, 3, ..., 9]
      test("+to > +beg, step = 2", () {
        expect(1.until(10, 2).toList(), List.generate(5, (i) => i + 1 + i));
      });

      /// Expected: []
      test("+to > +beg, -step", () {
        expect(1.until(10, -1).toList(), []);
      });

      /// Expected: []
      test("+to < +beg, +step", () {
        expect(10.until(1).toList(), []);
      });

      /// Expected: [10, ..., 2]
      test("+to < +beg, -step", () {
        expect(10.until(1, -1).toList(), List.generate(9, (i) => 10 - i));
      });

      /// Expected: [-10, ..., -2]
      test("-to > -beg, +step", () {
        expect((-10).until(-1, 1).toList(), List.generate(9, (i) => i + -10));
      });

      /// Expected: [-1, ..., -9]
      test("-to < -beg, -step", () {
        expect((-1).until(-10, -1).toList(), List.generate(9, (i) => -1 - i));
      });
    });
  });
}
