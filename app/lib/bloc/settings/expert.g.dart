// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expert.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $ExpertSettingsStateCopyWithWorker {
  ExpertSettingsState call({ExpertSettingsEvent? lastSuccessful});
}

class _$ExpertSettingsStateCopyWithWorkerImpl
    implements $ExpertSettingsStateCopyWithWorker {
  _$ExpertSettingsStateCopyWithWorkerImpl(this.that);

  @override
  ExpertSettingsState call({dynamic lastSuccessful = copyWithNull}) {
    return ExpertSettingsState(
        lastSuccessful: lastSuccessful == copyWithNull
            ? that.lastSuccessful
            : lastSuccessful as ExpertSettingsEvent?);
  }

  final ExpertSettingsState that;
}

extension $ExpertSettingsStateCopyWith on ExpertSettingsState {
  $ExpertSettingsStateCopyWithWorker get copyWith => _$copyWith;
  $ExpertSettingsStateCopyWithWorker get _$copyWith =>
      _$ExpertSettingsStateCopyWithWorkerImpl(this);
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
