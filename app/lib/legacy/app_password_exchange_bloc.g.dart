// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_password_exchange_bloc.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$AppPasswordExchangeBlocNpLog on AppPasswordExchangeBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log =
      Logger("legacy.app_password_exchange_bloc.AppPasswordExchangeBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$AppPasswordExchangeBlocConnectToString
    on AppPasswordExchangeBlocConnect {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AppPasswordExchangeBlocConnect {account: $account}";
  }
}

extension _$AppPasswordExchangeBlocSuccessToString
    on AppPasswordExchangeBlocSuccess {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AppPasswordExchangeBlocSuccess {password: ${isDevMode ? password : '***'}}";
  }
}

extension _$AppPasswordExchangeBlocFailureToString
    on AppPasswordExchangeBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AppPasswordExchangeBlocFailure {exception: $exception}";
  }
}
