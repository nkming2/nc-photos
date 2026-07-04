part of 'image_segment_picker.dart';

@npLog
class _IspBloc extends Bloc<_Event, _State> with BlocLogger {
  _IspBloc({required this.account, required this.file}) : super(_State.init()) {
    on<_Init>(_onInit);
    on<_NewPointPrompt>(_onNewPointPrompt);
    on<_PointPromptsUpdated>(_onPointPromptsUpdated, transformer: concurrent());
    on<_SetInitError>(_onSetInitError);

    _subscriptions.add(
      stream
          .distinct((a, b) => listEquals(a.pointPrompts, b.pointPrompts))
          .skip(1)
          .listen((event) {
            add(const _PointPromptsUpdated());
          }),
    );
  }

  @override
  Future<void> close() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onInit(_Init ev, _Emitter emit) async {
    _log.info(ev);
    if (!await _segmentationModel.isResourceReady()) {
      emit(state.copyWith(isReady: false));
      try {
        await _segmentationModel.prepareResource(
          onProgress: (progress, size) {
            emit(
              state.copyWith(downloadProgress: progress, downloadSize: size),
            );
          },
        );
        emit(state.copyWith(downloadSize: null));
      } catch (e, stackTrace) {
        _log.severe("Failed to prepare resource", e, stackTrace);
        add(_SetInitError(e, stackTrace));
        emit(state.copyWith(downloadProgress: 0, downloadSize: null));
        return;
      }
    }
    emit(state.copyWith(isReady: true));
  }

  void _onNewPointPrompt(_NewPointPrompt ev, _Emitter emit) {
    _log.info(ev);
    if (state.pointPrompts.length >= 6) {
      emit(state.copyWith(maxPointPromptsReached: Unique(true)));
      return;
    }
    // treat tapping closely as remove
    final removeIndex = state.pointPrompts.indexWhere(
      (p) => (p - ev.value).magnitude < 0.05,
    );
    if (removeIndex != -1) {
      emit(
        state.copyWith(pointPrompts: state.pointPrompts.removedAt(removeIndex)),
      );
    } else {
      emit(state.copyWith(pointPrompts: state.pointPrompts.added(ev.value)));
    }
  }

  Future<void> _onPointPromptsUpdated(
    _PointPromptsUpdated ev,
    _Emitter emit,
  ) async {
    _log.info(ev);
    final prompts = state.pointPrompts;
    final token = ++_pointPromptsToken;
    await _pointPromptsMutex.protect(() async {
      try {
        if (token != _pointPromptsToken) {
          _log.fine("[_onPointPromptsUpdated] Event outdated, dropping");
          return;
        }
        if (prompts.isEmpty) {
          emit(state.copyWith(extractionResult: null));
          return;
        }
        emit(state.copyWith(isLoading: true));
        final stopwatch = Stopwatch()..start();
        if (!await _segmentationModel.isResourceReady()) {
          // show dl dialog
          await _segmentationModel.prepareResource();
        }
        if (_srcImage == null) {
          final getter = AnyFileContentGetterFactory.binaryBitmap(
            file,
            account: account,
          );
          final size = _segmentationModel.getMaxSrcSize();
          final (:bytes, :bitmap) = await getter.get(
            maxWidth: size.width,
            maxHeight: size.height,
            shouldFixOrientation: true,
          );
          _srcImage = bitmap.toRgb();
        }
        final result = await _segmentationModel.apply(
          _srcImage!,
          points: prompts
              .map(
                (e) => Point(
                  (e.x * _srcImage!.width).toInt(),
                  (e.y * _srcImage!.height).toInt(),
                ),
              )
              .toList(),
          pointLabels: prompts.map((e) => 1).toList(),
        );
        if (token == _pointPromptsToken) {
          emit(state.copyWith(extractionResult: result));
        }
        _log.fine(
          "[_onPointPromptsUpdated] Elapsed time: ${stopwatch.elapsedMilliseconds}ms",
        );
      } finally {
        emit(state.copyWith(isLoading: false));
      }
    });
  }

  void _onSetInitError(_SetInitError ev, _Emitter emit) {
    _log.info(ev);
    emit(state.copyWith(initError: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  final Account account;
  final AnyFile file;

  final _subscriptions = <StreamSubscription>[];

  final _segmentationModel = PointPromptExtraction();
  Rgb8Image? _srcImage;

  final _pointPromptsMutex = Mutex();
  var _pointPromptsToken = 0;
}
