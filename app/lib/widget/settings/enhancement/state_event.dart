part of '../enhancement_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.isSaveEditResultToServer,
    this.error,
  });

  @override
  String toString() => _$toString();

  final bool isSaveEditResultToServer;

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
class _SetSaveEditResultToServer implements _Event {
  const _SetSaveEditResultToServer(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}
