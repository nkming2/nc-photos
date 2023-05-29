abstract class BlocTag {
  String get tag;
}

/// Wrap around a string such that two strings with the same value will fail
/// the identical check
class StateMessage {
  StateMessage(this.value);

  final String value;
}
