import 'dart:async';

import 'package:nc_photos/iterable_extension.dart';

Future<List<T>> waitOr<T>(
  Iterable<Future<T>> futures,
  T Function(Object error, StackTrace? stackTrace) onError,
) async {
  final completer = Completer<List<T>>();
  final results = List<T?>.filled(futures.length, null);
  var remaining = results.length;
  if (remaining == 0) {
    return Future.value(const []);
  }

  void onResult() {
    if (--remaining <= 0) {
      // finished
      completer.complete(results.cast<T>());
    }
  }

  for (final p in futures.withIndex()) {
    unawaited(
      p.item2.then((value) {
        results[p.item1] = value;
        onResult();
      }).onError((error, stackTrace) {
        results[p.item1] = onError(error!, stackTrace);
        onResult();
      }),
    );
  }
  return completer.future;
}
