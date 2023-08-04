part of '../viewer_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.screenBrightness,
    required this.isForceRotation,
    required this.gpsMapProvider,
    this.error,
  });

  @override
  String toString() => _$toString();

  final int screenBrightness;
  final bool isForceRotation;
  final GpsMapProvider gpsMapProvider;

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
class _SetScreenBrightness implements _Event {
  const _SetScreenBrightness(this.value);

  @override
  String toString() => _$toString();

  final double value;
}

@toString
class _SetForceRotation implements _Event {
  const _SetForceRotation(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}

@toString
class _SetGpsMapProvider implements _Event {
  const _SetGpsMapProvider(this.value);

  @override
  String toString() => _$toString();

  final GpsMapProvider value;
}
