// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logAccount = Logger("account.Account");

extension _$AccountNpLog on Account {
  // ignore: unused_element
  Logger get _log => _$logAccount;
}

// ignore: non_constant_identifier_names
final _$logAccountUpgraderV1 = Logger("account.AccountUpgraderV1");

extension _$AccountUpgraderV1NpLog on AccountUpgraderV1 {
  // ignore: unused_element
  Logger get _log => _$logAccountUpgraderV1;
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
