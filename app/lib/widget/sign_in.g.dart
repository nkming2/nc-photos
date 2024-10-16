// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_in.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call(
      {_Scheme? scheme,
      String? serverUrl,
      Unique<Uri>? connectUri,
      Account? connectedAccount,
      bool? isConnecting,
      bool? isCompleted,
      ExceptionEvent? error});
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call(
      {dynamic scheme,
      dynamic serverUrl,
      dynamic connectUri = copyWithNull,
      dynamic connectedAccount = copyWithNull,
      dynamic isConnecting,
      dynamic isCompleted,
      dynamic error = copyWithNull}) {
    return _State(
        scheme: scheme as _Scheme? ?? that.scheme,
        serverUrl: serverUrl as String? ?? that.serverUrl,
        connectUri: connectUri == copyWithNull
            ? that.connectUri
            : connectUri as Unique<Uri>?,
        connectedAccount: connectedAccount == copyWithNull
            ? that.connectedAccount
            : connectedAccount as Account?,
        isConnecting: isConnecting as bool? ?? that.isConnecting,
        isCompleted: isCompleted as bool? ?? that.isCompleted,
        error: error == copyWithNull ? that.error : error as ExceptionEvent?);
  }

  final _State that;
}

extension $_StateCopyWith on _State {
  $_StateCopyWithWorker get copyWith => _$copyWith;
  $_StateCopyWithWorker get _$copyWith => _$_StateCopyWithWorkerImpl(this);
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$_WrappedSignInNpLog on _WrappedSignIn {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.sign_in._WrappedSignIn");
}

extension _$_BlocNpLog on _Bloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.sign_in._Bloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {scheme: ${scheme.name}, serverUrl: $serverUrl, connectUri: $connectUri, connectedAccount: $connectedAccount, isConnecting: $isConnecting, isCompleted: $isCompleted, error: $error}";
  }
}

extension _$_SetSchemeToString on _SetScheme {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetScheme {value: ${value.name}}";
  }
}

extension _$_SetServerUrlToString on _SetServerUrl {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetServerUrl {value: $value}";
  }
}

extension _$_ConnectToString on _Connect {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_Connect {}";
  }
}

extension _$_SetConnectedAccountToString on _SetConnectedAccount {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetConnectedAccount {value: $value}";
  }
}

extension _$_SetErrorToString on _SetError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetError {error: $error, stackTrace: $stackTrace}";
  }
}
