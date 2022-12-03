import 'dart:math' as math;

import 'package:to_string/to_string.dart';

part 'progress_util.g.dart';

@toString
class IntProgress {
  IntProgress(this.max) : step = max <= 0 ? 1 : 1 / max;

  void next() {
    _current = math.min(_current + 1, max);
  }

  double get progress => max <= 0 ? 1 : _current / max;

  @override
  String toString() => _$toString();

  final int max;
  final double step;
  var _current = 0;
}

@ToString(ignoreNull: true)
class Progress {
  const Progress(this.progress, [this.text]);

  @override
  String toString() => _$toString();

  final double progress;
  final String? text;
}
