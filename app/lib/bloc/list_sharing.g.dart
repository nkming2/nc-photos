// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_sharing.dart';

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ListSharingBlocQueryToString on ListSharingBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListSharingBlocQuery {account: $account}";
  }
}

extension _$_ListSharingBlocShareRemovedToString
    on _ListSharingBlocShareRemoved {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ListSharingBlocShareRemoved {shares: ${shares.toReadableString()}}";
  }
}

extension _$_ListSharingBlocPendingSharedAlbumMovedToString
    on _ListSharingBlocPendingSharedAlbumMoved {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ListSharingBlocPendingSharedAlbumMoved {account: $account, file: ${file.path}, destination: $destination}";
  }
}

extension _$ListSharingBlocStateToString on ListSharingBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "ListSharingBlocState")} {account: $account, items: [length: ${items.length}]}";
  }
}

extension _$ListSharingBlocFailureToString on ListSharingBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ListSharingBlocFailure {account: $account, items: [length: ${items.length}], exception: $exception}";
  }
}
