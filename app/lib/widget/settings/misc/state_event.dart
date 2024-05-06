part of '../misc_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.isDoubleTapExit,
    this.error,
  });

  @override
  String toString() => _$toString();

  final bool isDoubleTapExit;

  final ExceptionEvent? error;
}

abstract class _Event {
  const _Event();
}

@toString
class _Init implements _Event {
  const _Init();

  @override
  String toString() => _$toString();
}

@toString
class _SetDoubleTapExit implements _Event {
  const _SetDoubleTapExit(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}
