import 'package:flutter/material.dart';
import 'package:np_gps_map/src/map_coord.dart';
import 'package:np_gps_map/src/native.dart';
import 'package:np_gps_map/src/native/google_gps_map.dart'
    if (dart.library.html) 'package:np_gps_map/src/web/google_gps_map.dart';
import 'package:np_gps_map/src/osm_gps_map.dart';
import 'package:np_platform_util/np_platform_util.dart';

enum GpsMapProvider {
  google,
  osm,
  ;
}

class GpsMap extends StatelessWidget {
  const GpsMap({
    super.key,
    required this.providerHint,
    required this.center,
    required this.zoom,
    this.onTap,
  });

  static void init() {
    if (getRawPlatform() == NpPlatform.android) {
      Native.isNewGMapsRenderer().then((value) => _isNewGMapsRenderer = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (providerHint == GpsMapProvider.osm ||
        (getRawPlatform() == NpPlatform.android && !_isNewGMapsRenderer)) {
      return OsmGpsMap(
        center: center,
        zoom: zoom,
        onTap: onTap,
      );
    } else {
      return GoogleGpsMap(
        center: center,
        zoom: zoom,
        onTap: onTap,
      );
    }
  }

  /// The backend to provide the actual map. This works as a hint only, the
  /// actual choice may be different depending on the runtime environment
  final GpsMapProvider providerHint;

  /// A pair of latitude and longitude coordinates, stored as degrees
  final MapCoord center;
  final double zoom;
  final void Function()? onTap;

  static bool _isNewGMapsRenderer = false;
}
