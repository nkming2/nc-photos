// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expert.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

extension $ExpertSettingsStateCopyWith on ExpertSettingsState {
  ExpertSettingsState copyWith(
          {Nullable<ExpertSettingsEvent>? lastSuccessful}) =>
      _$copyWith(lastSuccessful: lastSuccessful);

  ExpertSettingsState _$copyWith(
      {Nullable<ExpertSettingsEvent>? lastSuccessful}) {
    return ExpertSettingsState(
        lastSuccessful:
            lastSuccessful != null ? lastSuccessful.obj : this.lastSuccessful);
  }
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$ExpertSettingsBlocNpLog on ExpertSettingsBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.settings.expert.ExpertSettingsBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ExpertSettingsStateToString on ExpertSettingsState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ExpertSettingsState {lastSuccessful: $lastSuccessful}";
  }
}

extension _$ExpertSettingsClearCacheDatabaseToString
    on ExpertSettingsClearCacheDatabase {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ExpertSettingsClearCacheDatabase {}";
  }
}
