// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_enhancer.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call({
    _Method? selectedMethod,
    _ApplyState? saveState,
    double? downloadProgress,
    int? downloadSize,
    Unique<_ImageSegmentRequest>? imageSegmentRequest,
    ExceptionEvent? error,
    ExceptionEvent? applyError,
  });
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call({
    dynamic selectedMethod,
    dynamic saveState = copyWithNull,
    dynamic downloadProgress,
    dynamic downloadSize = copyWithNull,
    dynamic imageSegmentRequest = copyWithNull,
    dynamic error = copyWithNull,
    dynamic applyError = copyWithNull,
  }) {
    return _State(
      selectedMethod: selectedMethod as _Method? ?? that.selectedMethod,
      saveState: saveState == copyWithNull
          ? that.saveState
          : saveState as _ApplyState?,
      downloadProgress: downloadProgress as double? ?? that.downloadProgress,
      downloadSize: downloadSize == copyWithNull
          ? that.downloadSize
          : downloadSize as int?,
      imageSegmentRequest: imageSegmentRequest == copyWithNull
          ? that.imageSegmentRequest
          : imageSegmentRequest as Unique<_ImageSegmentRequest>?,
      error: error == copyWithNull ? that.error : error as ExceptionEvent?,
      applyError: applyError == copyWithNull
          ? that.applyError
          : applyError as ExceptionEvent?,
    );
  }

  final _State that;
}

extension $_StateCopyWith on _State {
  $_StateCopyWithWorker get copyWith => _$copyWith;
  $_StateCopyWithWorker get _$copyWith => _$_StateCopyWithWorkerImpl(this);
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$_IeBlocNpLog on _IeBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.image_enhancer.image_enhancer._IeBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_ImageSegmentRequestToString on _ImageSegmentRequest {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ImageSegmentRequest {method: ${method.name}, platformIdentifier: $platformIdentifier, outputFilename: $outputFilename, uploadInfo: $uploadInfo}";
  }
}

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {selectedMethod: ${selectedMethod.name}, saveState: ${saveState == null ? null : "${saveState!.name}"}, downloadProgress: ${downloadProgress.toStringAsFixed(3)}, downloadSize: $downloadSize, imageSegmentRequest: $imageSegmentRequest, error: $error, applyError: $applyError}";
  }
}

extension _$_ApplyToString on _Apply {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_Apply {}";
  }
}

extension _$_HelpToString on _Help {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_Help {}";
  }
}

extension _$_SelectMethodToString on _SelectMethod {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SelectMethod {value: ${value.name}}";
  }
}

extension _$_SetImageSegmentResultToString on _SetImageSegmentResult {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetImageSegmentResult {request: $request, result: $result}";
  }
}

extension _$_SetErrorToString on _SetError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetError {error: $error, stackTrace: $stackTrace}";
  }
}

extension _$_SetApplyErrorToString on _SetApplyError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetApplyError {error: $error, stackTrace: $stackTrace}";
  }
}
