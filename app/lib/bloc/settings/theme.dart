import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:copy_with/copy_with.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/theme.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'theme.g.dart';

@autoCopyWith
@toString
class ThemeSettingsState {
  const ThemeSettingsState({
    required this.isFollowSystemTheme,
    required this.isUseBlackInDarkTheme,
    required this.seedColor,
  });

  @override
  String toString() => _$toString();

  final bool isFollowSystemTheme;
  final bool isUseBlackInDarkTheme;
  final Color seedColor;
}

abstract class ThemeSettingsEvent {
  const ThemeSettingsEvent();
}

@toString
class ThemeSettingsSetFollowSystemTheme extends ThemeSettingsEvent {
  const ThemeSettingsSetFollowSystemTheme(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}

@toString
class ThemeSettingsSetUseBlackInDarkTheme extends ThemeSettingsEvent {
  const ThemeSettingsSetUseBlackInDarkTheme(this.value, this.theme);

  @override
  String toString() => _$toString();

  final bool value;
  final ThemeData theme;
}

@toString
class ThemeSettingsSetSeedColor extends ThemeSettingsEvent {
  const ThemeSettingsSetSeedColor(this.value);

  @override
  String toString() => _$toString();

  final Color value;
}

class ThemeSettingsError {
  const ThemeSettingsError(this.ev, [this.error, this.stackTrace]);

  final ThemeSettingsEvent ev;
  final Object? error;
  final StackTrace? stackTrace;
}

@npLog
class ThemeSettingsBloc extends Bloc<ThemeSettingsEvent, ThemeSettingsState> {
  ThemeSettingsBloc(DiContainer c)
      : assert(require(c)),
        _c = c,
        super(ThemeSettingsState(
          isFollowSystemTheme: c.pref.isFollowSystemThemeOr(false),
          isUseBlackInDarkTheme: c.pref.isUseBlackInDarkThemeOr(false),
          seedColor: getSeedColor(),
        )) {
    on<ThemeSettingsSetFollowSystemTheme>(_onSetFollowSystemTheme);
    on<ThemeSettingsSetUseBlackInDarkTheme>(_onSetUseBlackInDarkTheme);
    on<ThemeSettingsSetSeedColor>(_onSetSeedColor);
  }

  static bool require(DiContainer c) => DiContainer.has(c, DiType.pref);

  Stream<ThemeSettingsError> errorStream() => _errorStream.stream;

  Future<void> _onSetFollowSystemTheme(ThemeSettingsSetFollowSystemTheme ev,
      Emitter<ThemeSettingsState> emit) async {
    final oldValue = state.isFollowSystemTheme;
    emit(state.copyWith(isFollowSystemTheme: ev.value));
    if (await _c.pref.setFollowSystemTheme(ev.value)) {
      KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
    } else {
      _log.severe("[_onSetFollowSystemTheme] Failed writing pref");
      _errorStream.add(ThemeSettingsError(ev));
      emit(state.copyWith(isFollowSystemTheme: oldValue));
    }
  }

  Future<void> _onSetUseBlackInDarkTheme(ThemeSettingsSetUseBlackInDarkTheme ev,
      Emitter<ThemeSettingsState> emit) async {
    final oldValue = state.isUseBlackInDarkTheme;
    emit(state.copyWith(isUseBlackInDarkTheme: ev.value));
    if (await _c.pref.setUseBlackInDarkTheme(ev.value)) {
      if (ev.theme.brightness == Brightness.dark) {
        KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
      }
    } else {
      _log.severe("[_onSetUseBlackInDarkTheme] Failed writing pref");
      _errorStream.add(ThemeSettingsError(ev));
      emit(state.copyWith(isUseBlackInDarkTheme: oldValue));
    }
  }

  Future<void> _onSetSeedColor(
      ThemeSettingsSetSeedColor ev, Emitter<ThemeSettingsState> emit) async {
    final oldValue = state.seedColor;
    emit(state.copyWith(seedColor: ev.value));
    if (await _c.pref.setSeedColor(ev.value.withAlpha(0xFF).value)) {
      KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
    } else {
      _log.severe("[_onSetSeedColor] Failed writing pref");
      _errorStream.add(ThemeSettingsError(ev));
      emit(state.copyWith(seedColor: oldValue));
    }
  }

  final DiContainer _c;
  final _errorStream = StreamController<ThemeSettingsError>.broadcast();
}
