import 'package:np_common/unique.dart';
import 'package:test/test.dart';

void main() {
  group("Unique", () {
    test("same value", () {
      expect(Unique(1) == Unique(1), false);
    });

    test("same instance", () {
      final a = Unique(1);
      expect(a == a, true);
    });
  });
}
