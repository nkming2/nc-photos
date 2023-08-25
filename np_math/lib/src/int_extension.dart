extension IntExtension on int {
  Iterable<int> until(int to, [int step = 1]) sync* {
    if (step == 0) {
      throw ArgumentError("step must not be zero");
    }
    final sign = (to - this).sign;
    if (sign != step.sign) {
      // e.g., 0.until(10, -1) or 0.until(-10, 1)
      return;
    }
    for (var i = this; sign > 0 ? i < to : i > to; i += step) {
      yield i;
    }
  }
}
