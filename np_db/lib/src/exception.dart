import 'package:to_string/to_string.dart';

part 'exception.g.dart';

@ToString(ignoreNull: true)
class DbNotFoundException implements Exception {
  const DbNotFoundException([this.message]);

  @override
  String toString() => _$toString();

  final String? message;
}
