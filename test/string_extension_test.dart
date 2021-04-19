import 'package:test/test.dart';
import 'package:nc_photos/string_extension.dart';

void main() {
  group("StringExtension", () {
    test("trimLeftAny", () {
      expect(".,.123.,.321.,.".trimLeftAny(".,"), "123.,.321.,.");
    });

    test("trimRightAny", () {
      expect(".,.123.,.321.,.".trimRightAny(".,"), ".,.123.,.321");
    });

    test("trimAny", () {
      expect(".,.123.,.321.,.".trimAny(".,"), "123.,.321");
    });
  });
}
