part of 'image_enhancer.dart';

enum _ApplyState { init, prepareModel, download, background }

@toString
class _ImageSegmentRequest {
  const _ImageSegmentRequest({
    required this.method,
    required this.platformIdentifier,
    required this.filename,
    required this.uploadInfo,
  });

  @override
  String toString() => _$toString();

  final _Method method;
  final String platformIdentifier;
  final String filename;
  final ImageEnhancerServerPersistenceInfo? uploadInfo;
}

@genCopyWith
@toString
class _State {
  const _State({
    required this.selectedMethod,
    this.saveState,
    required this.downloadProgress,
    this.downloadSize,
    this.imageSegmentRequest,
    this.error,
    this.applyError,
  });

  factory _State.init() {
    return const _State(selectedMethod: _Method.retouch, downloadProgress: 0);
  }

  @override
  String toString() => _$toString();

  final _Method selectedMethod;
  final _ApplyState? saveState;
  final double downloadProgress;
  final int? downloadSize;

  final Unique<_ImageSegmentRequest>? imageSegmentRequest;

  final ExceptionEvent? error;
  final ExceptionEvent? applyError;
}

sealed class _Event {}

@toString
class _Apply implements _Event {
  const _Apply();

  @override
  String toString() => _$toString();
}

@toString
class _Help implements _Event {
  const _Help();

  @override
  String toString() => _$toString();
}

@toString
class _SelectMethod implements _Event {
  const _SelectMethod(this.value);

  @override
  String toString() => _$toString();

  final _Method value;
}

@toString
class _SetImageSegmentResult implements _Event {
  const _SetImageSegmentResult({required this.request, required this.result});

  @override
  String toString() => _$toString();

  final _ImageSegmentRequest request;
  final Rgba8Image result;
}

@toString
class _SetError implements _Event {
  const _SetError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}

@toString
class _SetApplyError implements _Event {
  const _SetApplyError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
