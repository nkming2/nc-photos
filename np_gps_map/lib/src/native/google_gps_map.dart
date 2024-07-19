import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:np_gps_map/src/map_coord.dart';

class GoogleGpsMap extends StatelessWidget {
  const GoogleGpsMap({
    super.key,
    required this.center,
    required this.zoom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final centerLl = LatLng(center.latitude, center.longitude);
    return GoogleMap(
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: false,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationButtonEnabled: false,
      buildingsEnabled: false,
      // liteModeEnabled: true,
      initialCameraPosition: CameraPosition(
        target: centerLl,
        zoom: zoom,
      ),
      markers: {
        Marker(
          markerId: const MarkerId("at"),
          position: centerLl,
          // for some reason, GoogleMap's onTap is not triggered if
          // tapped on top of the marker
          onTap: onTap,
        ),
      },
      onTap: (_) => onTap?.call(),
    );
  }

  final MapCoord center;
  final double zoom;
  final VoidCallback? onTap;
}
