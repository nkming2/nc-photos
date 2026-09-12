extension StopwatchExtension on Stopwatch {
  T measure<T>({
    required T Function() callback,
    required void Function(Duration time) timeCallback,
  }) {
    start();
    try {
      return callback();
    } finally {
      stop();
      timeCallback(elapsed);
    }
  }
}
