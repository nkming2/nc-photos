import 'package:np_gps_map/np_gps_map.dart';

extension GpsMapProviderExtension on GpsMapProvider {
  String toUserString() {
    switch (this) {
      case GpsMapProvider.google:
        return "Google Maps";
      case GpsMapProvider.osm:
        return "OpenStreetMap";
    }
  }
}
