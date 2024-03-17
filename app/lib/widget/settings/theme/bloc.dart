part of '../theme_settings.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.prefController,
  }) : super(_State(
          isFollowSystemTheme: prefController.isFollowSystemThemeValue,
          isUseBlackInDarkTheme: prefController.isUseBlackInDarkThemeValue,
          seedColor: prefController.seedColorValue?.value,
        )) {
    on<_Init>(_onInit);
    on<_SetFollowSystemTheme>(_onSetFollowSystemTheme);
    on<_SetUseBlackInDarkTheme>(_onSetUseBlackInDarkTheme);
    on<_SetSeedColor>(_onSetSeedColor);
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onInit(_Init ev, Emitter<_State> emit) async {
    _log.info(ev);
    await Future.wait([
      emit.forEach<bool>(
        prefController.isFollowSystemThemeChange,
        onData: (data) => state.copyWith(isFollowSystemTheme: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
      emit.forEach<bool>(
        prefController.isUseBlackInDarkThemeChange,
        onData: (data) => state.copyWith(isUseBlackInDarkTheme: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
      emit.forEach<Color?>(
        prefController.seedColorChange,
        onData: (data) => state.copyWith(seedColor: data?.value),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
    ]);
  }

  void _onSetFollowSystemTheme(_SetFollowSystemTheme ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setFollowSystemTheme(ev.value);
  }

  void _onSetUseBlackInDarkTheme(
      _SetUseBlackInDarkTheme ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setUseBlackInDarkTheme(ev.value);
  }

  void _onSetSeedColor(_SetSeedColor ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setSeedColor(ev.value);
  }

  final PrefController prefController;
}
