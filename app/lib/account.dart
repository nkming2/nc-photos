import 'dart:math';

import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/ci_string.dart';
import 'package:np_common/string_extension.dart';
import 'package:np_common/type.dart';
import 'package:to_string/to_string.dart';

part 'account.g.dart';

/// Details of a remote Nextcloud server account
@npLog
@toString
class Account with EquatableMixin {
  Account(
    this.id,
    this.scheme,
    String address,
    this.userId,
    this.username2,
    this.password,
    List<String> roots,
  )   : address = address.trimRightAny("/"),
        _roots = roots.map((e) => e.trimRightAny("/")).toList() {
    if (scheme != "http" && scheme != "https") {
      throw const FormatException("scheme is neither http or https");
    }
  }

  Account copyWith({
    String? id,
    String? scheme,
    String? address,
    CiString? userId,
    String? username2,
    String? password,
    List<String>? roots,
  }) {
    return Account(
      id ?? this.id,
      scheme ?? this.scheme,
      address ?? this.address,
      userId ?? this.userId,
      username2 ?? this.username2,
      password ?? this.password,
      roots ?? List.of(_roots),
    );
  }

  static String newId() {
    final timestamp = clock.now().millisecondsSinceEpoch;
    final random = Random().nextInt(0xFFFFFF);
    return "${timestamp.toRadixString(16)}-${random.toRadixString(16).padLeft(6, '0')}";
  }

  @override
  String toString() => _$toString();

  static Account? fromJson(
    JsonObj json, {
    required AccountUpgraderV1? upgraderV1,
  }) {
    final jsonVersion = json["version"] ?? 1;
    JsonObj? result = json;
    if (jsonVersion < 2) {
      result = upgraderV1?.call(result);
      if (result == null) {
        _log.info("[fromJson] Version $jsonVersion not compatible");
        return null;
      }
    }
    return Account(
      result["id"],
      result["scheme"],
      result["address"],
      CiString(result["userId"]),
      result["username2"],
      result["password"],
      result["roots"].cast<String>(),
    );
  }

  JsonObj toJson() => {
        "version": version,
        "id": id,
        "scheme": scheme,
        "address": address,
        "userId": userId.toString(),
        "username2": username2,
        "password": password,
        "roots": _roots,
      };

  @override
  get props => [id, scheme, address, userId, username2, password, _roots];

  List<String> get roots => _roots;

  final String id;
  final String scheme;
  @Format(r"${kDebugMode ? $? : '***'}")
  final String address;
  // For non LDAP users, this is the username used to sign in
  @Format(r"${kDebugMode ? $? : '***'}")
  final CiString userId;
  // Username used to sign in. For non-LDAP users, this is identical to userId
  @Format(r"${kDebugMode ? $? : '***'}")
  final String username2;
  @Format(r"${$?.isNotEmpty ? (kDebugMode ? $? : '***') : null}")
  final String password;

  @Format(r"${$?.toReadableString()}")
  final List<String> _roots;

  /// versioning of this class, use to upgrade old persisted accounts
  static const version = 2;

  static final _log = _$AccountNpLog.log;
}

extension AccountExtension on Account {
  String get url => "$scheme://$address";

  /// Compare the server identity of two Accounts
  ///
  /// Return true if two Accounts point to the same user on server. Be careful
  /// that this does NOT mean that the two Accounts are identical (e.g., they
  /// can have difference password)
  bool compareServerIdentity(Account other) {
    return scheme == other.scheme &&
        address == other.address &&
        userId == other.userId;
  }
}

abstract class AccountUpgrader {
  JsonObj? call(JsonObj json);
}

@npLog
class AccountUpgraderV1 implements AccountUpgrader {
  const AccountUpgraderV1({
    this.logAccountId,
  });

  @override
  call(JsonObj json) {
    // clarify user id and display name v1
    _log.fine("[call] Upgrade v1 Account: $logAccountId");
    final result = JsonObj.of(json);
    result["userId"] = json["altHomeDir"] ?? json["username"];
    result["username2"] = json["username"];
    result
      ..remove("username")
      ..remove("altHomeDir");
    return result;
  }

  /// Account ID for logging only
  final String? logAccountId;
}
