part of '../account_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.account,
    required this.shouldReload,
    required this.label,
    required this.shareFolder,
    required this.personProvider,
    required this.shouldResync,
    this.error,
  });

  factory _State.init({
    required Account account,
    required String? label,
    required String shareFolder,
    required PersonProvider personProvider,
  }) {
    return _State(
      shouldReload: false,
      account: account,
      label: label,
      shareFolder: shareFolder,
      personProvider: personProvider,
      shouldResync: false,
    );
  }

  @override
  String toString() => _$toString();

  final bool shouldReload;
  final Account account;
  final String? label;
  final String shareFolder;
  final PersonProvider personProvider;
  final bool shouldResync;

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
class _SetPersonProvider implements _Event {
  const _SetPersonProvider(this.personProvider);

  @override
  String toString() => _$toString();

  final PersonProvider personProvider;
}

@toString
class _OnUpdatePersonProvider implements _Event {
  const _OnUpdatePersonProvider(this.personProvider);

  @override
  String toString() => _$toString();

  final PersonProvider personProvider;
}

@toString
class _SetError implements _Event {
  const _SetError(this.error, [this.stackTrace]);

  @override
  String toString() => _$toString();

  final Object error;
  final StackTrace? stackTrace;
}
