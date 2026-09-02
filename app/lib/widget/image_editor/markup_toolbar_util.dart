import 'dart:math';

import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:np_ffi_image_editor/np_ffi_image_editor.dart' as image_editor;

part 'markup_toolbar_util.g.dart';

class BrushStroke {
  const BrushStroke({
    required this.id,
    required this.points,
    required this.radius,
    required this.color,
  });

  final int id;
  final List<Point<double>> points;
  final double radius;
  final Color color;
}

@genCopyWith
class MarkupArguments {
  const MarkupArguments({
    required this.strokes,
    this.color = const Color.fromARGB(255, 255, 0, 0),
    this.radius = .009,
  });

  image_editor.Edit? toEdit() {
    if (strokes.isEmpty) {
      return null;
    }
    return image_editor.BrushEdit(
      strokes: strokes
          .map(
            (s) => image_editor.BrushEditStroke(
              points: s.points,
              radius: s.radius,
              color: s.color,
            ),
          )
          .toList(),
    );
  }

  final List<BrushStroke> strokes;
  final Color color;
  final double radius;
}
