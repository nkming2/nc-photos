import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tuple/tuple.dart';

class Map extends StatelessWidget {
  const Map({
    Key key,
    this.center,
    this.zoom,
    this.onTap,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    final centerLl = LatLng(center.item1, center.item2);
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
          markerId: MarkerId("at"),
          position: centerLl,
          // for some reason, GoogleMap's onTap is not triggered if
          // tapped on top of the marker
          onTap: onTap,
        ),
      },
      onTap: (_) => onTap?.call(),
    );
  }

  /// A pair of latitude and longitude coordinates, stored as degrees
  final Tuple2<double, double> center;
  final double zoom;
  final void Function() onTap;
}
