import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:np_common/object_util.dart';
import 'package:np_gps_map/src/interactive_map.dart';
import 'package:np_gps_map/src/map_coord.dart';

typedef OsmClusterBuilder = Widget Function(
    BuildContext context, List<DataPoint> dataPoints);

class OsmInteractiveMap extends StatefulWidget {
  const OsmInteractiveMap({
    super.key,
    this.initialPosition,
    this.initialZoom,
    this.dataPoints,
    this.clusterBuilder,
    this.onClusterTap,
    this.contentPadding,
    this.onMapCreated,
  });

  @override
  State<StatefulWidget> createState() => _OsmInteractiveMapState();

  final MapCoord? initialPosition;
  final double? initialZoom;
  final List<DataPoint>? dataPoints;
  final OsmClusterBuilder? clusterBuilder;
  final void Function(List<DataPoint> dataPoints)? onClusterTap;
  final EdgeInsets? contentPadding;
  final void Function(InteractiveMapController controller)? onMapCreated;
}

class _OsmInteractiveMapState extends State<OsmInteractiveMap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_parentController == null) {
        _parentController = _ParentController(_controller);
        widget.onMapCreated?.call(_parentController!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.initialPosition?.toLatLng() ?? const LatLng(0, 0),
        initialZoom: max(2.5, widget.initialZoom ?? 2.5),
        minZoom: 2.5,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        if (widget.dataPoints != null)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              markers: widget.dataPoints!
                  .map((e) => _OsmDataPoint(
                        original: e,
                        child: _buildMarker(context, [e]),
                      ))
                  .toList(),
              builder: (context, markers) => _buildMarker(
                context,
                markers.cast<_OsmDataPoint>().map((e) => e.original).toList(),
              ),
            ),
          ),
        Padding(
          padding: widget.contentPadding ?? EdgeInsets.zero,
          child: const SimpleAttributionWidget(
            source: Text("OpenStreetMap contributors"),
          ),
        ),
      ],
    );
  }

  Widget _buildMarker(BuildContext context, List<DataPoint> dataPoints) {
    if (widget.clusterBuilder == null) {
      return const SizedBox.shrink();
    } else {
      return GestureDetector(
        onTap: widget.onClusterTap?.let((l) => () => l(dataPoints)),
        child: widget.clusterBuilder!(context, dataPoints),
      );
    }
  }

  _ParentController? _parentController;
  late final _controller = MapController();
}

class _OsmDataPoint extends Marker {
  _OsmDataPoint({
    required this.original,
    required super.child,
  }) : super(point: original.position.toLatLng());

  final DataPoint original;
}

class _ParentController implements InteractiveMapController {
  const _ParentController(this.controller);

  @override
  void setPosition(MapCoord position) {
    controller.move(position.toLatLng(), 10);
  }

  final MapController controller;
}

extension on MapCoord {
  LatLng toLatLng() => LatLng(latitude, longitude);
}
