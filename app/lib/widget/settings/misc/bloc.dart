part of '../misc_settings.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.prefController,
  }) : super(_State(
          isPhotosTabSortByName: prefController.isPhotosTabSortByName.value,
          isDoubleTapExit: prefController.isDoubleTapExit.value,
        )) {
    on<_Init>(_onInit);
    on<_SetPhotosTabSortByName>(_onSetPhotosTabSortByName);
    on<_SetDoubleTapExit>(_onSetDoubleTapExit);
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onInit(_Init ev, Emitter<_State> emit) async {
    _log.info(ev);
    await Future.wait([
      emit.forEach<bool>(
        prefController.isPhotosTabSortByName,
        onData: (data) => state.copyWith(isPhotosTabSortByName: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
      emit.forEach<bool>(
        prefController.isDoubleTapExit,
        onData: (data) => state.copyWith(isDoubleTapExit: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
    ]);
  }

  void _onSetPhotosTabSortByName(
      _SetPhotosTabSortByName ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setPhotosTabSortByName(ev.value);
  }

  void _onSetDoubleTapExit(_SetDoubleTapExit ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setDoubleTapExit(ev.value);
  }

  final PrefController prefController;
}
