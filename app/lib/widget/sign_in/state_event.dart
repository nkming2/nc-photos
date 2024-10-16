part of '../sign_in.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.scheme,
    required this.serverUrl,
    this.connectUri,
    this.connectedAccount,
    required this.isConnecting,
    required this.isCompleted,
    this.error,
  });

  factory _State.init() => const _State(
        scheme: _Scheme.https,
        serverUrl: "",
        isConnecting: false,
        isCompleted: false,
      );

  @override
  String toString() => _$toString();

  final _Scheme scheme;
  final String serverUrl;
  final Unique<Uri>? connectUri;
  final Account? connectedAccount;
  final bool isConnecting;
  final bool isCompleted;

  final ExceptionEvent? error;
}

abstract class _Event {}

@toString
class _SetScheme implements _Event {
  const _SetScheme(this.value);

  @override
  String toString() => _$toString();

  final _Scheme value;
}

@toString
class _SetServerUrl implements _Event {
  const _SetServerUrl(this.value);

  @override
  String toString() => _$toString();

  final String value;
}

@toString
class _Connect implements _Event {
  const _Connect();

  @override
  String toString() => _$toString();
}

@toString
class _SetConnectedAccount implements _Event {
  const _SetConnectedAccount(this.value);

  @override
  String toString() => _$toString();

  final Account value;
}

@toString
class _SetError implements _Event {
  const _SetError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
