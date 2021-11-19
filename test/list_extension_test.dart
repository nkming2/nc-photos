import 'package:nc_photos/list_extension.dart';
import 'package:test/test.dart';

void main() {
  group("ListExtension", () {
    test("takeIndex", () {
      expect([1, 2, 3, 4, 5, 6].takeIndex([5, 4, 3, 1, 0]), [6, 5, 4, 2, 1]);
    });
  });
}
