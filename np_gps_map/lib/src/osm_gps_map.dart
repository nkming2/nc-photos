import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:np_gps_map/src/type.dart';

class OsmGpsMap extends StatelessWidget {
  const OsmGpsMap({
    super.key,
    required this.center,
    required this.zoom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double pinSize = 48;
    final centerLl = LatLng(center.latitude, center.longitude);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // IgnorePointer is needed to prevent FlutterMap absorbing all pointer
      // events
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: centerLl,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: pinSize,
                  height: pinSize,
                  point: centerLl,
                  alignment: Alignment.topCenter,
                  child: const Image(
                    image: AssetImage(
                        "packages/np_gps_map/assets/gps_map_pin.png"),
                  ),
                ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text("OpenStreetMap contributors"),
            ),
          ],
        ),
      ),
    );
  }

  final MapCoord center;
  final double zoom;
  final void Function()? onTap;
}
