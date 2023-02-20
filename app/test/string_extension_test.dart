import 'package:nc_photos/string_extension.dart';
import 'package:test/test.dart';

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

    group("slice", () {
      const string = "hello world";
      test("+start", () {
        expect(string.slice(3), "lo world");
      });
      test("+start > length", () {
        expect(string.slice(999), "");
      });
      test("+start +stop", () {
        expect(string.slice(3, 5), "lo");
      });
      test("+start +stop > length", () {
        expect(string.slice(3, 999), "lo world");
      });
      test("+start > +stop", () {
        expect(string.slice(5, 3), "");
      });
      test("-start", () {
        expect(string.slice(-5), "world");
      });
      test("-start < -length", () {
        expect(string.slice(-999), "hello world");
      });
      test("-start -stop", () {
        expect(string.slice(-5, -3), "wo");
      });
      test("-start -stop < -length", () {
        expect(string.slice(-5, -999), "");
      });
      test("-start < -stop", () {
        expect(string.slice(-3, -5), "");
      });
      test("+start -stop", () {
        expect(string.slice(3, -5), "lo ");
      });
      test("-start +stop", () {
        expect(string.slice(-5, 9), "wor");
      });
    });
  });
}
