part of '../map_browser.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.data,
    this.initialPoint,
    required this.markers,
    this.error,
  });

  factory _State.init() {
    return const _State(
      data: [],
      markers: {},
    );
  }

  @override
  String toString() => _$toString();

  final List<_DataPoint> data;
  final LatLng? initialPoint;
  final Set<Marker> markers;

  final ExceptionEvent? error;
}

abstract class _Event {
  const _Event();
}

@toString
class _Init implements _Event {
  const _Init();

  @override
  String toString() => _$toString();
}

@toString
class _SetMarkers implements _Event {
  const _SetMarkers(this.markers);

  @override
  String toString() => _$toString();

  final Set<Marker> markers;
}

@toString
class _SetError implements _Event {
  const _SetError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
