// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ls_dir.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$LsDirBlocNpLog on LsDirBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.ls_dir.LsDirBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$LsDirBlocItemToString on LsDirBlocItem {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "LsDirBlocItem {file: ${file.path}, isE2ee: $isE2ee, children: ${children == null ? null : "[length: ${children!.length}]"}}";
  }
}

extension _$LsDirBlocQueryToString on LsDirBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "LsDirBlocQuery {account: $account, root: ${root.path}, depth: $depth}";
  }
}

extension _$LsDirBlocStateToString on LsDirBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "LsDirBlocState")} {account: $account, root: ${root.path}, items: [length: ${items.length}]}";
  }
}

extension _$LsDirBlocFailureToString on LsDirBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "LsDirBlocFailure {account: $account, root: ${root.path}, items: [length: ${items.length}], exception: $exception}";
  }
}
