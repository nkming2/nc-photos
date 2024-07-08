part of '../map_browser.dart';

@npLog
class _Bloc extends Bloc<_Event, _State>
    with BlocLogger, BlocForEachMixin<_Event, _State> {
  _Bloc(
    this._c, {
    required this.account,
  }) : super(_State.init()) {
    on<_Init>(_onInit);
    on<_SetMarkers>(_onSetMarkers);
    on<_SetError>(_onSetError);
  }

  @override
  String get tag => _log.fullName;

  @override
  void onError(Object error, StackTrace stackTrace) {
    // we need this to prevent onError being triggered recursively
    if (!isClosed && !_isHandlingError) {
      _isHandlingError = true;
      try {
        add(_SetError(error, stackTrace));
      } catch (_) {}
      _isHandlingError = false;
    }
    super.onError(error, stackTrace);
  }

  Future<void> _onInit(_Init ev, Emitter<_State> emit) async {
    _log.info(ev);
    final raw = await _c.imageLocationRepo.getLocations(account);
    _log.info("[_onInit] Loaded ${raw.length} markers");
    emit(state.copyWith(
      data: raw.map(_DataPoint.fromImageLatLng).toList(),
      initialPoint: state.initialPoint ??
          (raw.firstOrNull == null
              ? null
              : LatLng(raw.first.latitude, raw.first.longitude)),
    ));
  }

  void _onSetMarkers(_SetMarkers ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(markers: ev.markers));
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  final DiContainer _c;
  final Account account;

  var _isHandlingError = false;
}
