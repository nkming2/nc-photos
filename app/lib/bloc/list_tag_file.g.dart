// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_tag_file.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logListTagFileBloc = Logger("bloc.list_tag_file.ListTagFileBloc");

extension _$ListTagFileBlocNpLog on ListTagFileBloc {
  // ignore: unused_element
  Logger get _log => _$logListTagFileBloc;
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ListTagFileBlocQueryToString on ListTagFileBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListTagFileBlocQuery {account: $account, tag: $tag}";
  }
}

extension _$_ListTagFileBlocExternalEventToString
    on _ListTagFileBlocExternalEvent {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ListTagFileBlocExternalEvent {}";
  }
}

extension _$ListTagFileBlocStateToString on ListTagFileBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "ListTagFileBlocState")} {account: $account, items: [length: ${items.length}]}";
  }
}

extension _$ListTagFileBlocFailureToString on ListTagFileBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListTagFileBlocFailure {account: $account, items: [length: ${items.length}], exception: $exception}";
  }
}
