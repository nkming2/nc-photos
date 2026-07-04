part of 'image_segment_picker.dart';

@genCopyWith
@toString
class _State {
  const _State({
    this.isReady,
    required this.downloadProgress,
    this.downloadSize,
    required this.pointPrompts,
    this.extractionResult,
    required this.isLoading,
    this.initError,
    required this.maxPointPromptsReached,
  });

  factory _State.init() {
    return _State(
      downloadProgress: 0,
      pointPrompts: [],
      isLoading: false,
      maxPointPromptsReached: Unique(false),
    );
  }

  @override
  String toString() => _$toString();

  final bool? isReady;
  final double downloadProgress;
  final int? downloadSize;

  final List<Point<double>> pointPrompts;
  final Rgba8Image? extractionResult;
  final bool isLoading;

  final ExceptionEvent? initError;
  final Unique<bool> maxPointPromptsReached;
}

sealed class _Event {}

@toString
class _Init implements _Event {
  const _Init();

  @override
  String toString() => _$toString();
}

@toString
class _NewPointPrompt implements _Event {
  const _NewPointPrompt(this.value);

  @override
  String toString() => _$toString();

  final Point<double> value;
}

@toString
class _PointPromptsUpdated implements _Event {
  const _PointPromptsUpdated();

  @override
  String toString() => _$toString();
}

@toString
class _SetInitError implements _Event {
  const _SetInitError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
