// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_segment_picker.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call({
    bool? isReady,
    double? downloadProgress,
    int? downloadSize,
    List<Point<double>>? pointPrompts,
    Rgba8Image? extractionResult,
    bool? isLoading,
    ExceptionEvent? initError,
    Unique<bool>? maxPointPromptsReached,
  });
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call({
    dynamic isReady = copyWithNull,
    dynamic downloadProgress,
    dynamic downloadSize = copyWithNull,
    dynamic pointPrompts,
    dynamic extractionResult = copyWithNull,
    dynamic isLoading,
    dynamic initError = copyWithNull,
    dynamic maxPointPromptsReached,
  }) {
    return _State(
      isReady: isReady == copyWithNull ? that.isReady : isReady as bool?,
      downloadProgress: downloadProgress as double? ?? that.downloadProgress,
      downloadSize: downloadSize == copyWithNull
          ? that.downloadSize
          : downloadSize as int?,
      pointPrompts: pointPrompts as List<Point<double>>? ?? that.pointPrompts,
      extractionResult: extractionResult == copyWithNull
          ? that.extractionResult
          : extractionResult as Rgba8Image?,
      isLoading: isLoading as bool? ?? that.isLoading,
      initError: initError == copyWithNull
          ? that.initError
          : initError as ExceptionEvent?,
      maxPointPromptsReached:
          maxPointPromptsReached as Unique<bool>? ??
          that.maxPointPromptsReached,
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

extension _$_IspBlocNpLog on _IspBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger(
    "widget.image_segment_picker.image_segment_picker._IspBloc",
  );
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {isReady: $isReady, downloadProgress: ${downloadProgress.toStringAsFixed(3)}, downloadSize: $downloadSize, pointPrompts: [length: ${pointPrompts.length}], extractionResult: $extractionResult, isLoading: $isLoading, initError: $initError, maxPointPromptsReached: $maxPointPromptsReached}";
  }
}

extension _$_InitToString on _Init {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_Init {}";
  }
}

extension _$_NewPointPromptToString on _NewPointPrompt {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_NewPointPrompt {value: $value}";
  }
}

extension _$_PointPromptsUpdatedToString on _PointPromptsUpdated {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_PointPromptsUpdated {}";
  }
}

extension _$_SetInitErrorToString on _SetInitError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetInitError {error: $error, stackTrace: $stackTrace}";
  }
}
