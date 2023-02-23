import 'dart:math' as math;

extension StringExtension on String {
  /// Returns the string without any leading characters included in [characters]
  String trimLeftAny(String characters) {
    int i = 0;
    while (i < length && characters.contains(this[i])) {
      i += 1;
    }
    return substring(i);
  }

  /// Returns the string without any trailing characters included in
  /// [characters]
  String trimRightAny(String characters) {
    int i = 0;
    while (i < length && characters.contains(this[length - 1 - i])) {
      i += 1;
    }
    return substring(0, length - i);
  }

  /// Returns the string without any leading and trailing characters included in
  /// [characters]
  String trimAny(String characters) {
    return trimLeftAny(characters).trimRightAny(characters);
  }

  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();

  String slice(int start, [int? stop]) {
    if (start < 0) {
      start = math.max(length + start, 0);
    }
    if (stop != null && stop < 0) {
      stop = math.max(length + stop, 0);
    }
    if (start >= length) {
      return "";
    } else if (stop == null) {
      return substring(start);
    } else if (start >= stop) {
      return "";
    } else {
      return substring(start, math.min(stop, length));
    }
  }
}
