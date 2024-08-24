part of '../pref_controller.dart';

enum PrefMapDefaultRangeType {
  thisMonth(0),
  prevMonth(1),
  thisYear(2),
  ;

  const PrefMapDefaultRangeType(this.value);

  static PrefMapDefaultRangeType fromValue(int value) =>
      PrefMapDefaultRangeType.values[value];

  final int value;
}
