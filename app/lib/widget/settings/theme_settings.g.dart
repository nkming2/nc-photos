// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call(
      {bool? isFollowSystemTheme,
      bool? isUseBlackInDarkTheme,
      Color? seedColor});
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call(
      {dynamic isFollowSystemTheme,
      dynamic isUseBlackInDarkTheme,
      dynamic seedColor}) {
    return _State(
        isFollowSystemTheme:
            isFollowSystemTheme as bool? ?? that.isFollowSystemTheme,
        isUseBlackInDarkTheme:
            isUseBlackInDarkTheme as bool? ?? that.isUseBlackInDarkTheme,
        seedColor: seedColor as Color? ?? that.seedColor);
  }

  final _State that;
}

extension $_StateCopyWith on _State {
  $_StateCopyWithWorker get copyWith => _$copyWith;
  $_StateCopyWithWorker get _$copyWith => _$_StateCopyWithWorkerImpl(this);
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$_WrappedThemeSettingsStateNpLog on _WrappedThemeSettingsState {
  // ignore: unused_element
  Logger get _log => log;

  static final log =
      Logger("widget.settings.theme_settings._WrappedThemeSettingsState");
}

extension _$_BlocNpLog on _Bloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.settings.theme_settings._Bloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {isFollowSystemTheme: $isFollowSystemTheme, isUseBlackInDarkTheme: $isUseBlackInDarkTheme, seedColor: $seedColor}";
  }
}

extension _$_SetFollowSystemThemeToString on _SetFollowSystemTheme {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetFollowSystemTheme {value: $value}";
  }
}

extension _$_SetUseBlackInDarkThemeToString on _SetUseBlackInDarkTheme {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetUseBlackInDarkTheme {value: $value, theme: $theme}";
  }
}

extension _$_SetSeedColorToString on _SetSeedColor {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetSeedColor {value: $value}";
  }
}
