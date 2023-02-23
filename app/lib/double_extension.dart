import 'package:np_common/string_extension.dart';

extension DoubleExtension on double {
  /// Same as toStringAsFixed but with trailing zeros truncated
  String toStringAsFixedTruncated(int fractionDigits) {
    String tmp = toStringAsFixed(fractionDigits);
    if (fractionDigits == 0) {
      return tmp;
    }
    tmp = tmp.trimRightAny("0");
    if (tmp.endsWith(".")) {
      return tmp.substring(0, tmp.length - 1);
    } else {
      return tmp;
    }
  }
}
