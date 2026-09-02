// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'markup_toolbar_util.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $MarkupArgumentsCopyWithWorker {
  MarkupArguments call({
    List<BrushStroke>? strokes,
    Color? color,
    double? radius,
  });
}

class _$MarkupArgumentsCopyWithWorkerImpl
    implements $MarkupArgumentsCopyWithWorker {
  _$MarkupArgumentsCopyWithWorkerImpl(this.that);

  @override
  MarkupArguments call({dynamic strokes, dynamic color, dynamic radius}) {
    return MarkupArguments(
      strokes: strokes as List<BrushStroke>? ?? that.strokes,
      color: color as Color? ?? that.color,
      radius: radius as double? ?? that.radius,
    );
  }

  final MarkupArguments that;
}

extension $MarkupArgumentsCopyWith on MarkupArguments {
  $MarkupArgumentsCopyWithWorker get copyWith => _$copyWith;
  $MarkupArgumentsCopyWithWorker get _$copyWith =>
      _$MarkupArgumentsCopyWithWorkerImpl(this);
}
