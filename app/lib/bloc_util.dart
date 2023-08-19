import 'package:flutter_bloc/flutter_bloc.dart';

mixin BlocLogger {
  String? get tag => null;

  bool Function(dynamic currentState, dynamic nextState)? get shouldLog => null;
}

/// Wrap around a string such that two strings with the same value will fail
/// the identical check
class StateMessage {
  StateMessage(this.value);

  final String value;
}

extension EmitterExtension<State> on Emitter<State> {
  Future<void> forEachIgnoreError<T>(
    Stream<T> stream, {
    required State Function(T data) onData,
  }) =>
      onEach<T>(
        stream,
        onData: (data) => call(onData(data)),
        onError: (_, __) {},
      );
}
