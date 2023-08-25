import 'dart:math' as math;

import 'package:np_math/src/math_util.dart';
import 'package:test/test.dart';

void main() {
  group("math_util", () {
    test("degToRad", () {
      expect(degToRad(90), closeTo(1.570796, 1e-6));
    });
    test("radToDeg", () {
      expect(radToDeg(math.pi), 180);
    });
  });
}
