import 'package:flutter/material.dart';
import 'package:np_gps_map/src/interactive_map.dart';
import 'package:np_gps_map/src/type.dart';

class PlacePickerView extends StatelessWidget {
  const PlacePickerView({
    super.key,
    required this.providerHint,
    this.initialPosition,
    this.initialZoom,
    this.contentPadding,
    this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InteractiveMap(
          providerHint: providerHint,
          initialPosition: initialPosition,
          initialZoom: initialZoom,
          contentPadding: contentPadding,
          onCameraMove: onCameraMove,
        ),
        Positioned.fill(
          child: Transform.translate(
            // 48(height) / 2
            offset: const Offset(0, -24),
            child: Center(
              child: Image.asset("packages/np_gps_map/assets/gps_map_pin.png"),
            ),
          ),
        ),
      ],
    );
  }

  final GpsMapProvider providerHint;
  final MapCoord? initialPosition;
  final double? initialZoom;
  final EdgeInsets? contentPadding;
  final void Function(CameraPosition position)? onCameraMove;
}
