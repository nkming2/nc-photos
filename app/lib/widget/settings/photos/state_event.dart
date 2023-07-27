part of '../photos_settings.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.isEnableMemories,
    required this.isPhotosTabSortByName,
    required this.memoriesRange,
    this.error,
  });

  @override
  String toString() => _$toString();

  final bool isEnableMemories;
  final bool isPhotosTabSortByName;
  final int memoriesRange;

  final ExceptionEvent? error;
}

abstract class _Event {
  const _Event();
}

@toString
class _Init implements _Event {
  const _Init();

  @override
  String toString() => _$toString();
}

@toString
class _SetEnableMemories implements _Event {
  const _SetEnableMemories(this.value);

  @override
  String toString() => _$toString();

  final bool value;
}

@toString
class _SetMemoriesRange implements _Event {
  const _SetMemoriesRange(this.value);

  @override
  String toString() => _$toString();

  final int value;
}
