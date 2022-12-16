// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logSearchBloc = Logger("bloc.search.SearchBloc");

extension _$SearchBlocNpLog on SearchBloc {
  // ignore: unused_element
  Logger get _log => _$logSearchBloc;
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$SearchBlocQueryToString on SearchBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchBlocQuery {account: $account, criteria: $criteria}";
  }
}

extension _$_SearchBlocExternalEventToString on _SearchBlocExternalEvent {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SearchBlocExternalEvent {}";
  }
}

extension _$SearchBlocResetLandingToString on SearchBlocResetLanding {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchBlocResetLanding {account: $account}";
  }
}

extension _$SearchBlocStateToString on SearchBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "SearchBlocState")} {account: $account, criteria: $criteria, items: [length: ${items.length}]}";
  }
}

extension _$SearchBlocFailureToString on SearchBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchBlocFailure {account: $account, criteria: $criteria, items: [length: ${items.length}], exception: $exception}";
  }
}
