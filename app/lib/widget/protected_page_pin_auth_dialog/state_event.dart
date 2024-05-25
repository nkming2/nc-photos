part of '../protected_page_pin_auth_dialog.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.input,
    required this.obsecuredInput,
    required this.isAuthorized,
    required this.isPinError,
  });

  factory _State.init() => _State(
        input: "",
        obsecuredInput: const [],
        isAuthorized: false,
        isPinError: Unique(null),
      );

  @override
  String toString() => _$toString();

  final String input;
  final List<int> obsecuredInput;
  final bool isAuthorized;
  final Unique<bool?> isPinError;
}

abstract class _Event {
  const _Event();
}

@toString
class _PushDigit implements _Event {
  const _PushDigit(this.digit);

  @override
  String toString() => _$toString();

  final int digit;
}

@toString
class _PopDigit implements _Event {
  const _PopDigit();

  @override
  String toString() => _$toString();
}
