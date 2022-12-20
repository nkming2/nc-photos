// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$AccountNpLog on Account {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("account.Account");
}

extension _$AccountUpgraderV1NpLog on AccountUpgraderV1 {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("account.AccountUpgraderV1");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$AccountToString on Account {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "Account {id: $id, scheme: $scheme, address: ${kDebugMode ? address : '***'}, userId: ${kDebugMode ? userId : '***'}, username2: ${kDebugMode ? username2 : '***'}, password: ${password.isNotEmpty ? (kDebugMode ? password : '***') : null}, _roots: ${_roots.toReadableString()}}";
  }
}
