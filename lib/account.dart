import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/string_extension.dart';
import 'package:nc_photos/type.dart';

/// Details of a remote Nextcloud server account
class Account with EquatableMixin {
  Account(
    this.scheme,
    String address,
    this.username,
    this.password,
    List<String> roots,
  )   : address = address.trimRightAny("/"),
        _roots = roots.map((e) => e.trimRightAny("/")).toList() {
    if (scheme != "http" && scheme != "https") {
      throw const FormatException("scheme is neither http or https");
    }
  }

  Account copyWith({
    String? scheme,
    String? address,
    CiString? username,
    String? password,
    List<String>? roots,
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
        "address: '${kDebugMode ? address : "***"}', "
        "username: '${kDebugMode ? username : "***"}', "
        "password: '${password.isNotEmpty == true ? (kDebugMode ? password : '***') : null}', "
        "roots: List {'${roots.join('\', \'')}'}, "
        "}";
  }

  Account.fromJson(JsonObj json)
      : scheme = json["scheme"],
        address = json["address"],
        username = CiString(json["username"]),
        password = json["password"],
        _roots = json["roots"].cast<String>();

  JsonObj toJson() => {
        "scheme": scheme,
        "address": address,
        "username": username.toString(),
        "password": password,
        "roots": _roots,
      };

  @override
  List<Object> get props => [scheme, address, username, password, _roots];

  List<String> get roots => _roots;

  final String scheme;
  final String address;
  final CiString username;
  final String password;
  final List<String> _roots;
}

class AccountSettings with EquatableMixin {
  const AccountSettings({
    this.isEnableFaceRecognitionApp = true,
    this.shareFolder = "",
  });

  factory AccountSettings.fromJson(JsonObj json) {
    return AccountSettings(
      isEnableFaceRecognitionApp: json["isEnableFaceRecognitionApp"] ?? true,
      shareFolder: json["shareFolder"] ?? "",
    );
  }

  JsonObj toJson() => {
        "isEnableFaceRecognitionApp": isEnableFaceRecognitionApp,
        "shareFolder": shareFolder,
      };

  @override
  toString() {
    return "$runtimeType {"
        "isEnableFaceRecognitionApp: $isEnableFaceRecognitionApp, "
        "shareFolder: $shareFolder, "
        "}";
  }

  AccountSettings copyWith({
    bool? isEnableFaceRecognitionApp,
    String? shareFolder,
  }) {
    return AccountSettings(
      isEnableFaceRecognitionApp:
          isEnableFaceRecognitionApp ?? this.isEnableFaceRecognitionApp,
      shareFolder: shareFolder ?? this.shareFolder,
    );
  }

  @override
  get props => [
        isEnableFaceRecognitionApp,
        shareFolder,
      ];

  final bool isEnableFaceRecognitionApp;

  /// Path of the share folder
  ///
  /// Share folder is where files shared with you are initially placed. Must
  /// match the value of share_folder in config.php
  final String shareFolder;
}

extension AccountExtension on Account {
  String get url => "$scheme://$address";
}
