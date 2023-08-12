import 'dart:ui';

import 'package:flutter/material.dart';

class AppDimension extends ThemeExtension<AppDimension> {
  const AppDimension({
    required this.homeBottomAppBarHeight,
  });

  static AppDimension of(BuildContext context) =>
      Theme.of(context).extension<AppDimension>()!;

  @override
  AppDimension copyWith({
    double? homeBottomAppBarHeight,
  }) =>
      AppDimension(
        homeBottomAppBarHeight:
            homeBottomAppBarHeight ?? this.homeBottomAppBarHeight,
      );

  @override
  AppDimension lerp(ThemeExtension<AppDimension>? other, double t) {
    if (other is! AppDimension) {
      return this;
    }
    return AppDimension(
      homeBottomAppBarHeight:
          lerpDouble(homeBottomAppBarHeight, other.homeBottomAppBarHeight, t)!,
    );
  }

  final double homeBottomAppBarHeight;
}
