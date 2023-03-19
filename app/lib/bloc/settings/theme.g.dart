// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $ThemeSettingsStateCopyWithWorker {
  ThemeSettingsState call(
      {bool? isFollowSystemTheme,
      bool? isUseBlackInDarkTheme,
      Color? seedColor});
}

class _$ThemeSettingsStateCopyWithWorkerImpl
    implements $ThemeSettingsStateCopyWithWorker {
  _$ThemeSettingsStateCopyWithWorkerImpl(this.that);

  @override
  ThemeSettingsState call(
      {dynamic isFollowSystemTheme,
      dynamic isUseBlackInDarkTheme,
      dynamic seedColor}) {
    return ThemeSettingsState(
        isFollowSystemTheme:
            isFollowSystemTheme as bool? ?? that.isFollowSystemTheme,
        isUseBlackInDarkTheme:
            isUseBlackInDarkTheme as bool? ?? that.isUseBlackInDarkTheme,
        seedColor: seedColor as Color? ?? that.seedColor);
  }

  final ThemeSettingsState that;
}

extension $ThemeSettingsStateCopyWith on ThemeSettingsState {
  $ThemeSettingsStateCopyWithWorker get copyWith => _$copyWith;
  $ThemeSettingsStateCopyWithWorker get _$copyWith =>
      _$ThemeSettingsStateCopyWithWorkerImpl(this);
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$ThemeSettingsBlocNpLog on ThemeSettingsBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.settings.theme.ThemeSettingsBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ThemeSettingsStateToString on ThemeSettingsState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ThemeSettingsState {isFollowSystemTheme: $isFollowSystemTheme, isUseBlackInDarkTheme: $isUseBlackInDarkTheme, seedColor: $seedColor}";
  }
}

extension _$ThemeSettingsSetFollowSystemThemeToString
    on ThemeSettingsSetFollowSystemTheme {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ThemeSettingsSetFollowSystemTheme {value: $value}";
  }
}

extension _$ThemeSettingsSetUseBlackInDarkThemeToString
    on ThemeSettingsSetUseBlackInDarkTheme {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ThemeSettingsSetUseBlackInDarkTheme {value: $value, theme: $theme}";
  }
}

extension _$ThemeSettingsSetSeedColorToString on ThemeSettingsSetSeedColor {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ThemeSettingsSetSeedColor {value: $value}";
  }
}
