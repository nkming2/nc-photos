// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expert_settings.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call({_Event? lastSuccessful});
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call({dynamic lastSuccessful = copyWithNull}) {
    return _State(
        lastSuccessful: lastSuccessful == copyWithNull
            ? that.lastSuccessful
            : lastSuccessful as _Event?);
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

extension _$_WrappedExpertSettingsStateNpLog on _WrappedExpertSettingsState {
  // ignore: unused_element
  Logger get _log => log;

  static final log =
      Logger("widget.settings.expert_settings._WrappedExpertSettingsState");
}

extension _$_BlocNpLog on _Bloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.settings.expert_settings._Bloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {lastSuccessful: $lastSuccessful}";
  }
}

extension _$_ClearCacheDatabaseToString on _ClearCacheDatabase {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ClearCacheDatabase {}";
  }
}
