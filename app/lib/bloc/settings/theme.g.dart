// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

extension $ThemeSettingsStateCopyWith on ThemeSettingsState {
  ThemeSettingsState copyWith(
          {bool? isFollowSystemTheme,
          bool? isUseBlackInDarkTheme,
          Color? seedColor}) =>
      _$copyWith(
          isFollowSystemTheme: isFollowSystemTheme,
          isUseBlackInDarkTheme: isUseBlackInDarkTheme,
          seedColor: seedColor);

  ThemeSettingsState _$copyWith(
      {bool? isFollowSystemTheme,
      bool? isUseBlackInDarkTheme,
      Color? seedColor}) {
    return ThemeSettingsState(
        isFollowSystemTheme: isFollowSystemTheme ?? this.isFollowSystemTheme,
        isUseBlackInDarkTheme:
            isUseBlackInDarkTheme ?? this.isUseBlackInDarkTheme,
        seedColor: seedColor ?? this.seedColor);
  }
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
