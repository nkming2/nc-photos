part of '../expert_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    this.lastSuccessful,
  });

  @override
  String toString() => _$toString();

  final _Event? lastSuccessful;
}

abstract class _Event {
  const _Event();
}

@toString
class _ClearCacheDatabase extends _Event {
  _ClearCacheDatabase();

  @override
  String toString() => _$toString();
}
