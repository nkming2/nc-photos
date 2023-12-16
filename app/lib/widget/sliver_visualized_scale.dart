import 'package:flutter/material.dart';
import 'package:np_common/object_util.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Transitioned scaling between two slivers
class SliverTransitionedScale extends StatelessWidget {
  const SliverTransitionedScale({
    super.key,
    required this.scale,
    required this.baseSliver,
    required this.overlaySliver,
  });

  @override
  Widget build(BuildContext context) {
    return SliverStack(
      children: [
        SliverOpacity(
          opacity: scale?.let(_scaleToCurrentOpacity) ?? 1,
          sliver: baseSliver,
        ),
        if (scale != null)
          SliverOpacity(
            opacity: 1 - _scaleToCurrentOpacity(scale!),
            sliver: overlaySliver,
          ),
      ],
    );
  }

  /// Current scaling factor [0, 1], or null if not scaling
  final double? scale;
  final Widget baseSliver;
  final Widget overlaySliver;
}

double _scaleToCurrentOpacity(double scale) {
  if (scale < 1) {
    if (scale <= .3) {
      return 0;
    } else {
      return ((scale - .3) / .7).clamp(0, 1);
    }
  } else {
    if (scale >= 1.9) {
      return 0;
    } else {
      return (1 - (scale - 1) / .9).clamp(0, 1);
    }
  }
}
