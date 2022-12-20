// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_tag.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$ListTagBlocNpLog on ListTagBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.list_tag.ListTagBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ListTagBlocQueryToString on ListTagBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListTagBlocQuery {account: $account}";
  }
}

extension _$ListTagBlocStateToString on ListTagBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "ListTagBlocState")} {account: $account, items: [length: ${items.length}]}";
  }
}

extension _$ListTagBlocFailureToString on ListTagBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListTagBlocFailure {account: $account, items: [length: ${items.length}], exception: $exception}";
  }
}
