extension NumExtension on num {
  bool inRange(
    num beg,
    num end, {
    bool isBegInclusive = true,
    bool isEndInclusive = true,
  }) {
    return (this > beg || (isBegInclusive && this == beg)) &&
        (this < end || (isEndInclusive && this == end));
  }
}
