enum TimeRangeBound {
  inclusive,
  exclusive,
}

class TimeRange {
  const TimeRange({
    required this.from,
    this.fromBound = TimeRangeBound.inclusive,
    required this.to,
    this.toBound = TimeRangeBound.exclusive,
  });

  @override
  String toString() {
    return "${fromBound == TimeRangeBound.inclusive ? "[" : "("}"
        "$from, $to"
        "${toBound == TimeRangeBound.inclusive ? "]" : ")"}";
  }

  final DateTime from;
  final TimeRangeBound fromBound;
  final DateTime to;
  final TimeRangeBound toBound;
}

extension TimeRangeExtension on TimeRange {
  /// Return if an arbitrary time [a] is inside this range
  ///
  /// The comparison is independent of whether the time is in UTC or in the
  /// local time zone
  bool isIn(DateTime a) {
    if (a.isBefore(from)) {
      return false;
    }
    if (fromBound == TimeRangeBound.exclusive) {
      if (a.isAtSameMomentAs(from)) {
        return false;
      }
    }
    if (a.isAfter(to)) {
      return false;
    }
    if (toBound == TimeRangeBound.exclusive) {
      if (a.isAtSameMomentAs(to)) {
        return false;
      }
    }
    return true;
  }
}
