part of '../file_sharer.dart';

@genCopyWith
@toString
class _State {
  const _State({
    this.method,
    this.previewState,
    this.fileState,
    this.publicLinkState,
    this.passwordLinkState,
    this.result,
    this.error,
    this.message,
  });

  factory _State.init() {
    return const _State();
  }

  @override
  String toString() => _$toString();

  final ShareMethod? method;
  final _PreviewState? previewState;
  final _FileState? fileState;
  final _PublicLinkState? publicLinkState;
  final _PasswordLinkState? passwordLinkState;
  final bool? result;
  final ExceptionEvent? error;
  final String? message;
}

@genCopyWith
@toString
class _PreviewState {
  const _PreviewState({
    required this.index,
    required this.count,
  });

  @override
  String toString() => _$toString();

  final int index;
  final int count;
}

@genCopyWith
@toString
class _FileState {
  const _FileState({
    required this.index,
    required this.count,
  });

  @override
  String toString() => _$toString();

  final int index;
  final int count;
}

@toString
class _PublicLinkState {
  const _PublicLinkState();

  @override
  String toString() => _$toString();
}

@genCopyWith
@toString
class _PasswordLinkState {
  const _PasswordLinkState({
    this.password,
  });

  @override
  String toString() => _$toString();

  final String? password;
}

abstract class _Event {
  const _Event();
}

/// Set the share method to be used
@toString
class _SetMethod implements _Event {
  const _SetMethod(this.method);

  @override
  String toString() => _$toString();

  final ShareMethod method;
}

/// Set the result of the sharer and return it to the caller
@toString
class _SetResult implements _Event {
  const _SetResult(this.result);

  @override
  String toString() => _$toString();

  final bool result;
}

/// Set the details needed to share files as public link
@toString
class _SetPublicLinkDetails implements _Event {
  const _SetPublicLinkDetails({
    this.albumName,
  });

  @override
  String toString() => _$toString();

  final String? albumName;
}

/// Set the details needed to share files as password protected link
@toString
class _SetPasswordLinkDetails implements _Event {
  const _SetPasswordLinkDetails({
    this.albumName,
    required this.password,
  });

  @override
  String toString() => _$toString();

  final String? albumName;
  final String password;
}
