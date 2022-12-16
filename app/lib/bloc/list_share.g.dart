// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_share.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logListShareBloc = Logger("bloc.list_share.ListShareBloc");

extension _$ListShareBlocNpLog on ListShareBloc {
  // ignore: unused_element
  Logger get _log => _$logListShareBloc;
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ListShareBlocQueryToString on ListShareBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListShareBlocQuery {account: $account, file: ${file.path}}";
  }
}

extension _$ListShareBlocStateToString on ListShareBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "ListShareBlocState")} {account: $account, file: ${file.path}, items: [length: ${items.length}]}";
  }
}

extension _$ListShareBlocFailureToString on ListShareBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListShareBlocFailure {account: $account, file: ${file.path}, items: [length: ${items.length}], exception: $exception}";
  }
}
