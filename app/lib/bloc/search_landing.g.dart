// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_landing.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logSearchLandingBloc = Logger("bloc.search_landing.SearchLandingBloc");

extension _$SearchLandingBlocNpLog on SearchLandingBloc {
  // ignore: unused_element
  Logger get _log => _$logSearchLandingBloc;
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$SearchLandingBlocQueryToString on SearchLandingBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchLandingBlocQuery {account: $account}";
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
