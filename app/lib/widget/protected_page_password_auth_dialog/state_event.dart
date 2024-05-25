part of '../protected_page_password_auth_dialog.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.isAuthorized,
  });

  factory _State.init() => _State(
        isAuthorized: Unique(null),
      );

  @override
  String toString() => _$toString();

  final Unique<bool?> isAuthorized;
}

abstract class _Event {
  const _Event();
}

@toString
class _Submit implements _Event {
  const _Submit(this.value);

  @override
  String toString() => _$toString();

  final String value;
}
