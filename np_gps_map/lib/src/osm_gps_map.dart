import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
    final centerLl = LatLng(center.item1, center.item2);
    return GestureDetector(
      onTap: () {
        launchUrlString(
          "https://www.openstreetmap.org/?mlat=${center.item1}&mlon=${center.item2}#map=${zoom.toInt()}/${center.item1}/${center.item2}",
          mode: LaunchMode.externalApplication,
        );
      },
      behavior: HitTestBehavior.opaque,
      // IgnorePointer is needed to prevent FlutterMap absorbing all pointer
      // events
      child: IgnorePointer(
        child: FlutterMap(
          options: MapOptions(
            center: centerLl,
            zoom: zoom,
            allowPanning: false,
            enableScrollWheel: false,
            interactiveFlags: InteractiveFlag.none,
          ),
          nonRotatedChildren: [
            AttributionWidget.defaultWidget(
              source: "OpenStreetMap contributors",
            ),
          ],
          layers: [
            TileLayerOptions(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            ),
            MarkerLayerOptions(
              markers: [
                Marker(
                  width: pinSize,
                  height: pinSize,
                  point: centerLl,
                  anchorPos: AnchorPos.align(AnchorAlign.top),
                  builder: (_) => const Image(
                    image: AssetImage(
                        "packages/np_gps_map/assets/gps_map_pin.png"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  final Tuple2<double, double> center;
  final double zoom;
  final void Function()? onTap;
}
