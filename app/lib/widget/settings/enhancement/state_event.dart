part of '../enhancement_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.isSaveEditResultToServer,
    required this.maxSize,
    this.error,
  });

  @override
  String toString() => _$toString();

  final bool isSaveEditResultToServer;
  final SizeInt maxSize;

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

@toString
class _SetMaxSize implements _Event {
  const _SetMaxSize(this.value);

  @override
  String toString() => _$toString();

  final SizeInt value;
}
