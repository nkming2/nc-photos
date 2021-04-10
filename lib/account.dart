import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nc_photos/string_extension.dart';

/// Details of a remote Nextcloud server account
class Account with EquatableMixin {
  Account(
    this.scheme,
    String address,
    this.username,
    this.password,
    List<String> roots,
  )   : this.address = address.trimRightAny("/"),
        _roots = roots.map((e) => e.trimRightAny("/")).toList() {
    if (scheme != "http" && scheme != "https") {
      throw FormatException("scheme is neither http or https");
    }
  }

  Account copyWith({
    String scheme,
    String address,
    String username,
    String password,
    List<String> roots,
  }) {
    return Account(
      scheme ?? this.scheme,
      address ?? this.address,
      username ?? this.username,
      password ?? this.password,
      roots ?? _roots,
    );
  }

  @override
  toString() {
    return "$runtimeType {"
        "scheme: '$scheme', "
        "address: '$address', "
        "username: '$username', "
        "password: '${password?.isNotEmpty == true ? (kDebugMode ? password : '***') : null}', "
        "roots: List {'${roots.join('\', \'')}'}, "
        "}";
  }

  Account.fromJson(Map<String, dynamic> json)
      : scheme = json["scheme"],
        address = json["address"],
        username = json["username"],
        password = json["password"],
        _roots = json["roots"].cast<String>();

  Map<String, dynamic> toJson() => {
        "scheme": scheme,
        "address": address,
        "username": username,
        "password": password,
        "roots": _roots,
      };

  @override
  List<Object> get props => [scheme, address, username, password, _roots];

  List<String> get roots => _roots;

  final String scheme;
  final String address;
  final String username;
  final String password;
  final List<String> _roots;
}

extension AccountExtension on Account {
  String get url => "$scheme://$address";
}
