// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$SearchBlocNpLog on SearchBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.search.SearchBloc");
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
