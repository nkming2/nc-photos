// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_landing.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$SearchLandingBlocNpLog on SearchLandingBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.search_landing.SearchLandingBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$SearchLandingBlocQueryToString on SearchLandingBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchLandingBlocQuery {account: $account, accountPrefController: $accountPrefController}";
  }
}

extension _$SearchLandingBlocStateToString on SearchLandingBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "SearchLandingBlocState")} {account: $account, persons: [length: ${persons.length}], locations: $locations}";
  }
}

extension _$SearchLandingBlocFailureToString on SearchLandingBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchLandingBlocFailure {account: $account, persons: [length: ${persons.length}], locations: $locations, exception: $exception}";
  }
}
