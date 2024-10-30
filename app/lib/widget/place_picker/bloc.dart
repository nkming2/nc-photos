part of 'place_picker.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc() : super(_State.init()) {
    on<_SetPosition>(_onSetPosition);
  }

  @override
  String get tag => _log.fullName;

  @override
  bool Function(dynamic, dynamic)? get shouldLog => (currentState, nextState) {
        return currentState.position == nextState.position;
      };

  void _onSetPosition(_SetPosition ev, _Emitter emit) {
    // _log.info(ev);
    emit(state.copyWith(position: ev.value));
  }
}
