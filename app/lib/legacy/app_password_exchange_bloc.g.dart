// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_password_exchange_bloc.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logAppPasswordExchangeBloc =
    Logger("legacy.app_password_exchange_bloc.AppPasswordExchangeBloc");

extension _$AppPasswordExchangeBlocNpLog on AppPasswordExchangeBloc {
  // ignore: unused_element
  Logger get _log => _$logAppPasswordExchangeBloc;
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
    return "AppPasswordExchangeBlocSuccess {password: ${kDebugMode ? password : '***'}}";
  }
}

extension _$AppPasswordExchangeBlocFailureToString
    on AppPasswordExchangeBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AppPasswordExchangeBlocFailure {exception: $exception}";
  }
}
