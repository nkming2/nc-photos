import 'package:flutter/material.dart';
import 'package:nc_photos/entity/file.dart';

class CustomizableMaterialPageRoute extends MaterialPageRoute {
  CustomizableMaterialPageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    required this.transitionDuration,
    required this.reverseTransitionDuration,
  });

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;
}

String getImageHeroTag(File file) => "imageHero(${file.path})";
