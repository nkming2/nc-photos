part of 'enhance_result_viewer.dart';

@genCopyWith
@toString
class _State {
  const _State({this.file, this.error});

  factory _State.init() => const _State();

  @override
  String toString() => _$toString();

  final AnyFile? file;
  final ExceptionEvent? error;
}

sealed class _Event {}

@toString
class _LoadFile implements _Event {
  const _LoadFile();

  @override
  String toString() => _$toString();
}

@toString
class _SetError implements _Event {
  const _SetError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
