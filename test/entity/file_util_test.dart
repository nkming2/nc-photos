import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:test/test.dart';

void main() {
  group("renameConflict", () {
    test("w/ extension", () {
      expect(file_util.renameConflict("test.jpg", 2), "test (2).jpg");
    });

    test("w/o extension", () {
      expect(file_util.renameConflict("test", 2), "test (2)");
    });
  });
}
