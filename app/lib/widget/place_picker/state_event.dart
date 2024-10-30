part of 'place_picker.dart';

@genCopyWith
@toString
class _State {
  const _State({
    this.position,
  });

  factory _State.init() => const _State();

  @override
  String toString() => _$toString();

  final CameraPosition? position;
}

abstract class _Event {}

@toString
class _SetPosition implements _Event {
  const _SetPosition(this.value);

  @override
  String toString() => _$toString();

  final CameraPosition value;
}
