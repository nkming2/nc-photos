import 'package:to_string/to_string.dart';

part 'or_null.g.dart';

/// To hold optional arguments that themselves could be null
@toString
class OrNull<T> {
  OrNull(this.obj);

  /// Return iff the value of [x] is set to null, which means if [x] itself is
  /// null, false will still be returned
  static bool isSetNull(OrNull? x) => x != null && x.obj == null;

  @override
  String toString() => _$toString();

  final T? obj;
}
