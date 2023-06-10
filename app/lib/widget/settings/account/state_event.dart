part of '../account_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.account,
    required this.shouldReload,
    required this.label,
    required this.shareFolder,
    required this.isEnableFaceRecognitionApp,
    this.error,
  });

  factory _State.init({
    required Account account,
    required String? label,
    required String shareFolder,
    required bool isEnableFaceRecognitionApp,
  }) {
    return _State(
      shouldReload: false,
      account: account,
      label: label,
      shareFolder: shareFolder,
      isEnableFaceRecognitionApp: isEnableFaceRecognitionApp,
    );
  }

  @override
  String toString() => _$toString();

  final bool shouldReload;
  final Account account;
  final String? label;
  final String shareFolder;
  final bool isEnableFaceRecognitionApp;

  final ExceptionEvent? error;
}

class _AccountConflictError implements Exception {
  const _AccountConflictError();
}

@toString
class _WritePrefError implements Exception {
  const _WritePrefError([this.error, this.stackTrace]);

  @override
  String toString() => _$toString();

  final Error? error;
  final StackTrace? stackTrace;
}

abstract class _Event {}

@toString
class _SetLabel implements _Event {
  const _SetLabel(this.label);

  @override
  String toString() => _$toString();

  final String? label;
}

@toString
class _OnUpdateLabel implements _Event {
  const _OnUpdateLabel(this.label);

  @override
  String toString() => _$toString();

  final String? label;
}

@toString
class _SetAccount implements _Event {
  const _SetAccount(this.account);

  @override
  String toString() => _$toString();

  final Account account;
}

@toString
class _OnUpdateAccount implements _Event {
  const _OnUpdateAccount(this.account);

  @override
  String toString() => _$toString();

  final Account account;
}

@toString
class _SetShareFolder implements _Event {
  const _SetShareFolder(this.shareFolder);

  @override
  String toString() => _$toString();

  final String shareFolder;
}

@toString
class _OnUpdateShareFolder implements _Event {
  const _OnUpdateShareFolder(this.shareFolder);

  @override
  String toString() => _$toString();

  final String shareFolder;
}

@toString
class _SetEnableFaceRecognitionApp implements _Event {
  const _SetEnableFaceRecognitionApp(this.isEnableFaceRecognitionApp);

  @override
  String toString() => _$toString();

  final bool isEnableFaceRecognitionApp;
}

@toString
class _OnUpdateEnableFaceRecognitionApp implements _Event {
  const _OnUpdateEnableFaceRecognitionApp(this.isEnableFaceRecognitionApp);

  @override
  String toString() => _$toString();

  final bool isEnableFaceRecognitionApp;
}

@toString
class _SetError implements _Event {
  const _SetError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
