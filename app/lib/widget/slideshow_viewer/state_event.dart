part of '../slideshow_viewer.dart';

@genCopyWith
@toString
class _State {
  const _State({
    required this.hasInit,
    required this.page,
    required this.nextPage,
    required this.currentFile,
    required this.isShowUi,
  });

  factory _State.init({
    required FileDescriptor initialFile,
  }) =>
      _State(
        hasInit: false,
        page: 0,
        nextPage: 0,
        currentFile: initialFile,
        isShowUi: false,
      );

  @override
  String toString() => _$toString();

  final bool hasInit;
  final int page;
  final int nextPage;
  final FileDescriptor currentFile;
  final bool isShowUi;
}

abstract class _Event {}

@toString
class _Init implements _Event {
  const _Init();

  @override
  String toString() => _$toString();
}

@toString
class _ToggleShowUi implements _Event {
  const _ToggleShowUi();

  @override
  String toString() => _$toString();
}

@toString
class _PreloadSidePages implements _Event {
  const _PreloadSidePages(this.center);

  @override
  String toString() => _$toString();

  final int center;
}

@toString
class _VideoCompleted implements _Event {
  const _VideoCompleted(this.page);

  @override
  String toString() => _$toString();

  final int page;
}

@toString
class _SetCurrentPage implements _Event {
  const _SetCurrentPage(this.value);

  @override
  String toString() => _$toString();

  final int value;
}

@toString
class _NextPage implements _Event {
  const _NextPage(this.value);

  @override
  String toString() => _$toString();

  final int value;
}
