double tremblingTransform(int count, double t) {
  final tt = (t * count) % 1;
  return _tremblingTransformT(tt);
}

double _tremblingTransformT(double t) {
  if (t <= 0 || t >= 1) {
    return 0;
  }
  final x = 4 * t;
  if (x < 1) {
    return -x;
  } else if (x < 3) {
    return x - 1;
  } else {
    return 4 - x;
  }
}
