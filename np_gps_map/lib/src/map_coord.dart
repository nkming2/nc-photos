class MapCoord {
  const MapCoord(this.latitude, this.longitude);

  @override
  String toString() => "MapCoord {latitude: $latitude, longitude: $longitude}";

  final double latitude;
  final double longitude;
}
