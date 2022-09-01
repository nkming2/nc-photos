import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:tuple/tuple.dart';

enum GpsMapProvider {
  // the order must not be changed
  google,
  osm,
}

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

class GpsMap extends StatelessWidget {
  const GpsMap({
    Key? key,
    required this.center,
    required this.zoom,
    this.onTap,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    if (GpsMapProvider.values[Pref().getGpsMapProviderOr(0)] ==
            GpsMapProvider.osm ||
        (platform_k.isAndroid && !app_init.isNewGMapsRenderer())) {
      return _OsmGpsMap(
        center: center,
        zoom: zoom,
        onTap: onTap,
      );
    } else {
      return _GoogleGpsMap(
        center: center,
        zoom: zoom,
        onTap: onTap,
      );
    }
  }

  /// A pair of latitude and longitude coordinates, stored as degrees
  final Tuple2<double, double> center;
  final double zoom;
  final void Function()? onTap;
}

typedef _GoogleGpsMap = platform.GoogleGpsMap;

class _OsmGpsMap extends StatelessWidget {
  const _OsmGpsMap({
    Key? key,
    required this.center,
    required this.zoom,
    this.onTap,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    const double pinSize = 48;
    final centerLl = LatLng(center.item1, center.item2);
    return GestureDetector(
      onTap: () {
        launch(
            "https://www.openstreetmap.org/?mlat=${center.item1}&mlon=${center.item2}#map=${zoom.toInt()}/${center.item1}/${center.item2}");
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
                  builder: (context) => const Image(
                    image: AssetImage("assets/gps_map_pin.png"),
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
