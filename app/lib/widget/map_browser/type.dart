part of '../map_browser.dart';

class _DataPoint implements ClusterItem {
  const _DataPoint({
    required this.location,
    required this.fileId,
  });

  factory _DataPoint.fromImageLatLng(ImageLatLng src) => _DataPoint(
        location: LatLng(src.latitude, src.longitude),
        fileId: src.fileId,
      );

  @override
  String get geohash =>
      Geohash.encode(location, codeLength: ClusterManager.precision);

  @override
  final LatLng location;
  final int fileId;
}

enum _DateRangeType {
  thisMonth,
  prevMonth,
  thisYear,
  custom,
  ;

  String toDisplayString() {
    switch (this) {
      case thisMonth:
        return L10n.global().mapBrowserDateRangeThisMonth;
      case prevMonth:
        return L10n.global().mapBrowserDateRangePrevMonth;
      case thisYear:
        return L10n.global().mapBrowserDateRangeThisYear;
      case custom:
        return L10n.global().mapBrowserDateRangeCustom;
    }
  }
}

extension on MapCoord {
  LatLng toLatLng() => LatLng(latitude, longitude);
}
