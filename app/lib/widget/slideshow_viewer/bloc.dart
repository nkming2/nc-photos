part of '../slideshow_viewer.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.account,
    required this.files,
    required this.startIndex,
    required this.config,
  }) : super(_State.init(
          initialFile: files[startIndex],
        )) {
    on<_Init>(_onInit);
    on<_ToggleShowUi>(_onToggleShowUi);
    on<_PreloadSidePages>(_onPreloadSidePages);
    on<_VideoCompleted>(_onVideoCompleted);
    on<_SetCurrentPage>(_onSetCurrentPage);
    on<_NextPage>(_onNextPage);
  }

  @override
  Future<void> close() {
    _showUiTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }

  @override
  String get tag => _log.fullName;

  /// Convert the page index to the corresponding item index
  int convertPageToFileIndex(int pageIndex) =>
      _shuffledIndex[pageIndex % files.length];

  void _onInit(_Init ev, Emitter<_State> emit) {
    _log.info(ev);
    final parsedConfig = _parseConfig(
      files: files,
      startIndex: startIndex,
      config: config,
    );
    _shuffledIndex = parsedConfig.shuffled;
    initialPage = parsedConfig.initial;
    pageCount = parsedConfig.count;
    emit(state.copyWith(
      hasInit: true,
      page: initialPage,
      currentFile: _getFileByPageIndex(initialPage),
    ));
    _prepareNextPage();
  }

  void _onToggleShowUi(_ToggleShowUi ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(isShowUi: !state.isShowUi));
    if (state.isShowUi) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      _showUiTimer?.cancel();
      _showUiTimer = Timer(
        const Duration(seconds: 3),
        () {
          if (state.isShowUi) {
            add(const _ToggleShowUi());
          }
        },
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  void _onPreloadSidePages(_PreloadSidePages ev, Emitter<_State> emit) {
    _log.info(ev);
    // currently pageview doesn't pre-load pages, we do it manually
    // don't pre-load if user already navigated away
    if (state.page != ev.center) {
      return;
    }
    _log.info("[_onPreloadSidePages] Pre-loading nearby images");
    if (ev.center > 0) {
      final fileIndex = convertPageToFileIndex(ev.center - 1);
      final prevFile = files[fileIndex];
      if (file_util.isSupportedImageFormat(prevFile)) {
        RemoteImageViewer.preloadImage(account, prevFile);
      }
    }
    if (pageCount == null || ev.center + 1 < pageCount!) {
      final fileIndex = convertPageToFileIndex(ev.center + 1);
      final nextFile = files[fileIndex];
      if (file_util.isSupportedImageFormat(nextFile)) {
        RemoteImageViewer.preloadImage(account, nextFile);
      }
    }
  }

  void _onVideoCompleted(_VideoCompleted ev, Emitter<_State> emit) {
    _log.info(ev);
    _gotoNextPage();
  }

  void _onSetCurrentPage(_SetCurrentPage ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(
      page: ev.value,
      currentFile: _getFileByPageIndex(ev.value),
    ));
    _prepareNextPage();
  }

  void _onNextPage(_NextPage ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(nextPage: ev.value));
  }

  static ({List<int> shuffled, int initial, int? count}) _parseConfig({
    required List<FileDescriptor> files,
    required int startIndex,
    required SlideshowConfig config,
  }) {
    final index = [for (var i = 0; i < files.length; ++i) i];
    final count = config.isRepeat ? null : files.length;
    if (config.isShuffle) {
      return (
        shuffled: index..shuffle(),
        initial: 0,
        count: count,
      );
    } else if (config.isReverse) {
      return (
        shuffled: index.reversed.toList(),
        initial: files.length - 1 - startIndex,
        count: count,
      );
    } else {
      return (
        shuffled: index,
        initial: startIndex,
        count: count,
      );
    }
  }

  Future<void> _prepareNextPage() async {
    final file = state.currentFile;
    if (file_util.isSupportedVideoFormat(file)) {
      // for videos, we need to wait until it's ended
      return;
    }
    // for photos, we wait for a fixed amount of time defined in config
    await Future.delayed(config.duration);
    _gotoNextPage();
  }

  void _gotoNextPage() {
    if (isClosed) {
      return;
    }
    final nextPage = state.page + 1;
    if (pageCount != null && nextPage >= pageCount!) {
      // end reached
      _log.info("[_gotoNextSlide] Reached the end");
      return;
    }
    _log.info("[_gotoNextSlide] Next page: $nextPage");
    add(_NextPage(nextPage));
  }

  FileDescriptor _getFileByPageIndex(int pageIndex) =>
      files[convertPageToFileIndex(pageIndex)];

  final Account account;
  final List<FileDescriptor> files;
  final int startIndex;
  final SlideshowConfig config;

  late final List<int> _shuffledIndex;
  late final int initialPage;
  late final int? pageCount;

  final _subscriptions = <StreamSubscription>[];
  Timer? _showUiTimer;
}
