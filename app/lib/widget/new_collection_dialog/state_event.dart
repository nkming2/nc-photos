part of '../new_collection_dialog.dart';

@genCopyWith
class _FormValue {
  const _FormValue({
    this.name = "",
    this.provider = _ProviderOption.appAlbum,
    this.dirs = const [],
    this.tags = const [],
  });

  final String name;
  final _ProviderOption provider;
  final List<File> dirs;
  final List<Tag> tags;
}

@genCopyWith
class _State {
  const _State({
    required this.supportedProviders,
    required this.formValue,
    this.result,
    required this.showDialog,
  });

  factory _State.init({
    required Set<_ProviderOption> supportedProviders,
  }) {
    return _State(
      supportedProviders: supportedProviders,
      formValue: const _FormValue(),
      showDialog: true,
    );
  }

  @keep
  final Set<_ProviderOption> supportedProviders;

  final _FormValue formValue;
  final Collection? result;
  final bool showDialog;
}

abstract class _Event {
  const _Event();
}

abstract class _FormEvent implements _Event {
  const _FormEvent();
}

@toString
class _SubmitName extends _FormEvent {
  const _SubmitName(this.value);

  @override
  String toString() => _$toString();

  final String value;
}

@toString
class _SubmitProvider extends _FormEvent {
  const _SubmitProvider(this.value);

  @override
  String toString() => _$toString();

  final _ProviderOption value;
}

@toString
class _SubmitDirs extends _FormEvent {
  const _SubmitDirs(this.value);

  @override
  String toString() => _$toString();

  final List<File> value;
}

@toString
class _SubmitTags extends _FormEvent {
  const _SubmitTags(this.value);

  @override
  String toString() => _$toString();

  final List<Tag> value;
}

@toString
class _SubmitForm extends _FormEvent {
  const _SubmitForm();

  @override
  String toString() => _$toString();
}

@toString
class _HideDialog extends _Event {
  const _HideDialog();

  @override
  String toString() => _$toString();
}
