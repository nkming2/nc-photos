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
