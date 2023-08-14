import 'package:flutter/material.dart';
import 'package:to_string/to_string.dart';

part 'size.g.dart';

/// Decimal size
@toString
class SizeInt {
  const SizeInt(this.width, this.height);

  SizeInt.square(int dimension) : this(dimension, dimension);

  @override
  bool operator ==(Object? other) {
    return other is SizeInt && width == other.width && height == other.height;
  }

  @override
  int get hashCode => Object.hash(width, height);

  Size toSizeF() => Size(width.toDouble(), height.toDouble());

  @override
  String toString() => _$toString();

  final int width;
  final int height;
}
