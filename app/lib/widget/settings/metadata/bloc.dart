part of '../metadata_settings.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.prefController,
  }) : super(_State(
          isEnable: prefController.isEnableExif.value,
          isWifiOnly: prefController.shouldProcessExifWifiOnly.value,
        )) {
    on<_Init>(_onInit);
    on<_SetEnable>(_onSetEnable);
    on<_SetWifiOnly>(_onSetWifiOnly);
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onInit(_Init ev, Emitter<_State> emit) async {
    _log.info(ev);
    await Future.wait([
      emit.forEach<bool>(
        prefController.isEnableExif,
        onData: (data) => state.copyWith(isEnable: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
      emit.forEach<bool>(
        prefController.shouldProcessExifWifiOnly,
        onData: (data) => state.copyWith(isWifiOnly: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
    ]);
  }

  void _onSetEnable(_SetEnable ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setEnableExif(ev.value);
  }

  Future<void> _onSetWifiOnly(_SetWifiOnly ev, Emitter<_State> emit) async {
    _log.info(ev);
    await prefController.setProcessExifWifiOnly(ev.value);
    ServiceConfig.setProcessExifWifiOnly(ev.value).ignore();
  }

  final PrefController prefController;
}
