import 'package:nc_photos/debug_util.dart';
import 'package:test/test.dart';

void main() {
  group("debug_util", () {
    group("logFilename", () {
      shouldLogFileName = false;

      test("null", () {
        expect(logFilename(null), "null");
      });
      test("path + name + ext", () {
        expect(logFilename("path/to/a/fancy_file.ext"), "***/fan***ile.ext");
      });
      test("path + short name + ext", () {
        expect(logFilename("path/to/a/file01.ext"), "***/file01.ext");
      });
      test("path + name", () {
        expect(logFilename("path/to/a/fancy_file"), "***/fan***ile");
      });
      test("name + ext", () {
        expect(logFilename("fancy_file"), "fan***ile");
      });
      test("name", () {
        expect(logFilename("fancy_file.ext"), "fan***ile.ext");
      });
    });
  });
}
