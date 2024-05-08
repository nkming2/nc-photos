extension DateTimeExtension on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    if (isUtc) {
      return DateTime.utc(
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
        millisecond ?? this.millisecond,
        microsecond ?? this.microsecond,
      );
    } else {
      return DateTime(
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
        millisecond ?? this.millisecond,
        microsecond ?? this.microsecond,
      );
    }
  }

  /// Returns true if [this] occurs before or at the same moment as [other].
  ///
  /// The comparison is independent
  /// of whether the time is in UTC or in the local time zone.
  bool isBeforeOrAt(DateTime other) => !isAfter(other);

  /// Returns true if [this] occurs after or at the same moment as [other].
  ///
  /// The comparison is independent
  /// of whether the time is in UTC or in the local time zone.
  bool isAfterOrAt(DateTime other) => !isBefore(other);
}
