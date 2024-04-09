extension DateTimeExtension on DateTime {
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
