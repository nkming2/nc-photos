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
}
