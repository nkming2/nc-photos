// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_album.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$ListAlbumBlocNpLog on ListAlbumBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.list_album.ListAlbumBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ListAlbumBlocQueryToString on ListAlbumBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListAlbumBlocQuery {account: $account}";
  }
}

extension _$_ListAlbumBlocExternalEventToString on _ListAlbumBlocExternalEvent {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ListAlbumBlocExternalEvent {}";
  }
}

extension _$ListAlbumBlocStateToString on ListAlbumBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "ListAlbumBlocState")} {account: $account, items: [length: ${items.length}]}";
  }
}

extension _$ListAlbumBlocFailureToString on ListAlbumBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListAlbumBlocFailure {account: $account, items: [length: ${items.length}], exception: $exception}";
  }
}
