import 'dart:math' as math;

import 'package:nc_photos/math_util.dart' as math_util;
import 'package:test/test.dart';

void main() {
  group("math_util", () {
    test("degToRad", () {
      expect(math_util.degToRad(90), closeTo(1.570796, 1e-6));
    });
    test("radToDeg", () {
      expect(math_util.radToDeg(math.pi), 180);
    });
  });
}
