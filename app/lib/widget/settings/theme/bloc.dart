part of '../theme_settings.dart';

class _Error {
  const _Error(this.ev);

  final _Event ev;
}

@npLog
class _Bloc extends Bloc<_Event, _State> {
  _Bloc(DiContainer c)
      : assert(require(c)),
        _c = c,
        super(_State(
          isFollowSystemTheme: c.pref.isFollowSystemThemeOr(false),
          isUseBlackInDarkTheme: c.pref.isUseBlackInDarkThemeOr(false),
          seedColor: getSeedColor(),
        )) {
    on<_SetFollowSystemTheme>(_onSetFollowSystemTheme);
    on<_SetUseBlackInDarkTheme>(_onSetUseBlackInDarkTheme);
    on<_SetSeedColor>(_onSetSeedColor);
  }

  static bool require(DiContainer c) => DiContainer.has(c, DiType.pref);

  Stream<_Error> errorStream() => _errorStream.stream;

  Future<void> _onSetFollowSystemTheme(
      _SetFollowSystemTheme ev, Emitter<_State> emit) async {
    final oldValue = state.isFollowSystemTheme;
    emit(state.copyWith(isFollowSystemTheme: ev.value));
    if (await _c.pref.setFollowSystemTheme(ev.value)) {
      KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
    } else {
      _log.severe("[_onSetFollowSystemTheme] Failed writing pref");
      _errorStream.add(_Error(ev));
      emit(state.copyWith(isFollowSystemTheme: oldValue));
    }
  }

  Future<void> _onSetUseBlackInDarkTheme(
      _SetUseBlackInDarkTheme ev, Emitter<_State> emit) async {
    final oldValue = state.isUseBlackInDarkTheme;
    emit(state.copyWith(isUseBlackInDarkTheme: ev.value));
    if (await _c.pref.setUseBlackInDarkTheme(ev.value)) {
      if (ev.theme.brightness == Brightness.dark) {
        KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
      }
    } else {
      _log.severe("[_onSetUseBlackInDarkTheme] Failed writing pref");
      _errorStream.add(_Error(ev));
      emit(state.copyWith(isUseBlackInDarkTheme: oldValue));
    }
  }

  Future<void> _onSetSeedColor(_SetSeedColor ev, Emitter<_State> emit) async {
    final oldValue = state.seedColor;
    emit(state.copyWith(seedColor: ev.value));
    if (await _c.pref.setSeedColor(ev.value.withAlpha(0xFF).value)) {
      KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
    } else {
      _log.severe("[_onSetSeedColor] Failed writing pref");
      _errorStream.add(_Error(ev));
      emit(state.copyWith(seedColor: oldValue));
    }
  }

  final DiContainer _c;
  final _errorStream = StreamController<_Error>.broadcast();
}
