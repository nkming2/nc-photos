import 'package:to_string/to_string.dart';

part 'unique.g.dart';

/// An unique value does not compare equal with others having the same value,
/// instead only the same instances are considered equal
@toString
class Unique<T> {
  // no const!
  Unique(this.value);

  @override
  String toString() => _$toString();

  final T value;
}
