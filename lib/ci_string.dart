import 'package:nc_photos/string_extension.dart';

/// Case-insensitive string
class CiString implements Comparable<Object> {
  CiString([this.raw = ""]) : _lower = raw.toLowerCase();

  @override
  operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    } else if (other is String) {
      return raw.equalsIgnoreCase(other);
    } else if (other is CiString) {
      return _lower == other._lower;
    } else {
      return false;
    }
  }

  @override
  get hashCode => raw.toLowerCase().hashCode;

  /// See [String.compareTo]
  @override
  compareTo(Object other) {
    if (other is String) {
      return _lower.compareTo(other.toLowerCase());
    } else if (other is CiString) {
      return _lower.compareTo(other._lower);
    } else {
      throw TypeError();
    }
  }

  /// See [String.endsWith]
  bool endsWith(Object other) {
    if (other is String) {
      return _lower.endsWith(other.toLowerCase());
    } else if (other is CiString) {
      return _lower.endsWith(other._lower);
    } else {
      throw TypeError();
    }
  }

  /// See [String.startsWith]
  bool startsWith(Object other) {
    if (other is String) {
      return _lower.startsWith(other.toLowerCase());
    } else if (other is CiString) {
      return _lower.startsWith(other._lower);
    } else {
      throw TypeError();
    }
  }

  /// See [String.contains]
  bool contains(Pattern other, [int startIndex = 0]) {
    if (other is String) {
      return _lower.contains(other.toLowerCase());
    } else if (other is RegExp) {
      if (other.isCaseSensitive) {
        final ciRegex = RegExp(
          other.pattern,
          multiLine: other.isMultiLine,
          caseSensitive: false,
          unicode: other.isUnicode,
          dotAll: other.isDotAll,
        );
        return ciRegex.hasMatch(raw);
      } else {
        return other.hasMatch(raw);
      }
    } else {
      throw UnimplementedError();
    }
  }

  @override
  toString() => raw;

  String toCaseInsensitiveString() => _lower;

  final String raw;
  final String _lower;
}

extension StringCiExtension on String {
  /// Convert to a case-insensitive string
  CiString toCi() => CiString(this);
}
