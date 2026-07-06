part of 'image_enhancer.dart';

@npLog
class _IeBloc extends Bloc<_Event, _State> with BlocLogger {
  _IeBloc({
    required this.prefController,
    required this.account,
    required this.file,
  }) : super(_State.init()) {
    on<_Apply>(_onApply);
    on<_Help>(_onHelp);
    on<_SelectMethod>(_onSelectMethod);
    on<_SetImageSegmentResult>(_onSetImageSegmentResult);

    on<_SetError>(_onSetError);
    on<_SetApplyError>(_onSetApplyError);
  }

  @override
  String get tag => _log.fullName;

  @override
  bool Function(dynamic, dynamic)? get shouldLog => (currentState, nextState) {
    currentState = currentState as _State;
    nextState = nextState as _State;
    return currentState.downloadProgress == nextState.downloadProgress;
  };

  @override
  void onError(Object error, StackTrace stackTrace) {
    // we need this to prevent onError being triggered recursively
    if (!isClosed && !_isHandlingError) {
      _isHandlingError = true;
      try {
        add(_SetError(error, stackTrace));
      } catch (_) {}
      _isHandlingError = false;
    }
    super.onError(error, stackTrace);
  }

  Future<void> _onApply(_Apply ev, _Emitter emit) async {
    _log.info(ev);
    emit(
      state.copyWith(
        saveState: _ApplyState.init,
        downloadProgress: 0,
        downloadSize: null,
      ),
    );

    try {
      final selectedMethod = state.selectedMethod;
      final taskType = selectedMethod.toImageEnhancerTask();
      final method = switch (selectedMethod) {
        _Method.retouch ||
        _Method.lowLight ||
        _Method.superResolution ||
        _Method.derain => taskType.toTorchMethod(),
        _Method.portraitBlur || _Method.colorPop => PointPromptExtraction(),
      };
      if (!await method.isResourceReady()) {
        try {
          await method.prepareResource(
            onProgress: (progress, size) {
              emit(
                state.copyWith(
                  saveState: _ApplyState.prepareModel,
                  downloadProgress: progress,
                  downloadSize: size,
                ),
              );
            },
          );
          emit(state.copyWith(downloadSize: null));
        } catch (e, stackTrace) {
          _log.severe("[_onApply] Failed to prepare resource", e, stackTrace);
          add(_SetApplyError(e, stackTrace));
          emit(
            state.copyWith(
              saveState: null,
              downloadProgress: 0,
              downloadSize: null,
            ),
          );
          return;
        }
      }

      final Uri uri;
      try {
        final getter = AnyFileContentGetterFactory.localFileUri(
          file,
          isPublic: false,
          account: account,
        );
        uri = await getter.get(
          onProgress: (progress) {
            emit(
              state.copyWith(
                saveState: _ApplyState.download,
                downloadProgress: progress,
              ),
            );
          },
        );
      } catch (e, stackTrace) {
        _log.severe("[_onApply] Failed to load file", e, stackTrace);
        add(_SetApplyError(e, stackTrace));
        emit(state.copyWith(saveState: null, downloadProgress: 0));
        return;
      }
      ImageEnhancerServerPersistenceInfo? uploadInfo;
      final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final outputFilename =
          "${path_lib.basenameWithoutExtension(file.name)}_enhanced_$epoch.jpg";
      if (prefController.isSaveEditResultToServerValue) {
        final remoteFile = switch (file.provider) {
          AnyFileNextcloudProvider _ =>
            (file.provider as AnyFileNextcloudProvider).file,
          AnyFileLocalProvider _ => null,
          AnyFileMergedProvider _ =>
            (file.provider as AnyFileMergedProvider).remote.file,
        };
        if (remoteFile != null) {
          final origPath = remoteFile.fdPath;
          final dirName = path_lib.dirname(origPath);
          final dstPath = "${dirName == "." ? "" : "$dirName/"}$outputFilename";
          uploadInfo = ImageEnhancerServerPersistenceInfo(
            baseUrl: account.url,
            endpoint: dstPath,
            headers: {
              "Authorization": AuthUtil.fromAccount(account).toHeaderValue(),
            },
          );
        }
      }

      if (selectedMethod.isRequireImageSegment) {
        emit(
          state.copyWith(
            imageSegmentRequest: Unique(
              _ImageSegmentRequest(
                method: selectedMethod,
                platformIdentifier: uri.toString(),
                outputFilename: outputFilename,
                uploadInfo: uploadInfo,
              ),
            ),
          ),
        );
        return;
      }
      _startEnhanceTask(
        type: taskType,
        platformIdentifier: uri.toString(),
        outputFilename: outputFilename,
        uploadInfo: uploadInfo,
      );
      emit(
        state.copyWith(saveState: _ApplyState.background, downloadProgress: 0),
      );
    } catch (e, stackTrace) {
      _log.severe("[_onApply] Failed to apply", e, stackTrace);
      add(_SetApplyError(e, stackTrace));
      emit(state.copyWith(saveState: null));
    }
  }

  void _onHelp(_Help ev, _Emitter emit) {
    _log.info(ev);
    launch(state.selectedMethod.helpUri.toString());
  }

  void _onSelectMethod(_SelectMethod ev, _Emitter emit) {
    _log.info(ev);
    emit(state.copyWith(selectedMethod: ev.value));
  }

  Future<void> _onSetImageSegmentResult(
    _SetImageSegmentResult ev,
    _Emitter emit,
  ) async {
    _log.info(ev);
    try {
      if (_isInitialDownload) {
        await _tempFileManager.cleanUp();
        _isInitialDownload = false;
      }
      final file = await _tempFileManager.createUnnamedFile(extension: "png");
      await image_lib.encodePngFile(
        file.path,
        image_lib.Image.fromBytes(
          width: ev.result.width,
          height: ev.result.height,
          bytes: ev.result.pixel.buffer,
          numChannels: 4,
        ),
      );
      _startEnhanceTask(
        type: ev.request.method.toImageEnhancerTask(),
        platformIdentifier: ev.request.platformIdentifier,
        outputFilename: ev.request.outputFilename,
        uploadInfo: ev.request.uploadInfo,
        imageSegment: file,
      );
      emit(state.copyWith(saveState: _ApplyState.background));
    } catch (e, stackTrace) {
      _log.severe("[_onApply] Failed to apply", e, stackTrace);
      add(_SetApplyError(e, stackTrace));
      emit(state.copyWith(saveState: null));
    }
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  void _onSetApplyError(_SetApplyError ev, _Emitter emit) {
    _log.info(ev);
    emit(state.copyWith(applyError: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  void _startEnhanceTask({
    required ImageEnhancerTaskType type,
    required String platformIdentifier,
    required String outputFilename,
    required ImageEnhancerServerPersistenceInfo? uploadInfo,
    io.File? imageSegment,
  }) {
    Workmanager().registerOneOffTask(
      "image-enhancer",
      "imageEnhancer",
      initialDelay: Duration.zero,
      existingWorkPolicy: ExistingWorkPolicy.append,
      inputData: ImageEnhancerTask.encodeArgument(
        strings: ImageEnhancerTaskStrings(
          imageEnhancerResultSuccessfulNotifTitle:
              L10n.global().imageEnhancerResultSuccessfulNotifTitle,
          imageEnhancerResultSuccessfulNotifContent:
              L10n.global().imageEnhancerResultSuccessfulNotifContent,
          imageEnhancerResultFailedNotifTitle:
              L10n.global().imageEnhancerResultFailedNotifTitle,
        ),
        type: type,
        platformIdentifier: platformIdentifier,
        outputFilename: outputFilename,
        uploadInfo: uploadInfo,
        imageSegment: imageSegment,
      ),
      // reuse the legacy one defined in ImageProcessorService
      androidForegroundInfo: AndroidForegroundInfo(
        notificationChannelId:
            ImageEnhancerAndroidConstant.notificationChannelId,
        notificationChannelName:
            ImageEnhancerAndroidConstant.notificationChannelName,
        notificationChannelDescription:
            ImageEnhancerAndroidConstant.notificationChannelDescription,
        notificationChannelImportance:
            ImageEnhancerAndroidConstant.notificationChannelImportance,
        notificationTitle: L10n.global().imageEditProcessDialogTitle,
        foregroundServiceType:
            ImageEnhancerAndroidConstant.foregroundServiceType,
        notificationId: ImageEnhancerAndroidConstant.notificationId,
      ),
    );
  }

  final PrefController prefController;
  final Account account;
  final AnyFile file;

  var _isHandlingError = false;

  static var _isInitialDownload = true;
  static const _tempFileManager = TempFileManager("image_enhancer");
}
