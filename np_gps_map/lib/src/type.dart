import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:np_common/type.dart';

class CameraPosition with EquatableMixin {
  const CameraPosition({
    required this.center,
    required this.zoom,
    required this.rotation,
  });

  factory CameraPosition.fromJson(JsonObj json) {
    return CameraPosition(
      center: LatLng.fromJson(json["center"]),
      zoom: json["zoom"],
      rotation: json["rotation"],
    );
  }

  @override
  String toString() => "CameraPosition {"
      "center: $center, "
      "zoom: $zoom, "
      "rotation: $rotation, "
      "}";

  JsonObj toJson() {
    return {
      "center": center.toJson(),
      "zoom": zoom,
      "rotation": rotation,
    };
  }

  @override
  List<Object?> get props => [center, zoom, rotation];

  final LatLng center;
  final double zoom;
  // The camera's bearing in degrees, measured clockwise from north.
  //
  // A bearing of 0.0, the default, means the camera points north.
  // A bearing of 90.0 means the camera points east.
  final double rotation;
}
