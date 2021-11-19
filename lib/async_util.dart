import 'dart:async';

Future<void> wait(
  FutureOr<bool> Function() condition, {
  Duration? pollInterval,
}) async {
  while (!await condition()) {
    await Future.delayed(pollInterval ?? const Duration(milliseconds: 500));
  }
}
