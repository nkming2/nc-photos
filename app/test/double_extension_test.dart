import 'package:nc_photos/double_extension.dart';
import 'package:test/test.dart';

void main() {
  group("DoubleExtension", () {
    test("toStringAsFixedTruncated", () {
      expect(1.23456.toStringAsFixedTruncated(4), "1.2346");
      expect(1.23001.toStringAsFixedTruncated(4), "1.23");
      expect(1.23.toStringAsFixedTruncated(4), "1.23");
      expect(1.0.toStringAsFixedTruncated(4), "1");
    });
  });
}
