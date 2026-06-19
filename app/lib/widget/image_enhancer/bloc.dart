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

    final taskType = state.selectedMethod.toImageEnhancerTask();
    final method = taskType.toTorchMethod();
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
        _log.severe("Failed to prepare resource", e, stackTrace);
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
      _log.severe("Failed to load file", e, stackTrace);
      add(_SetApplyError(e, stackTrace));
      emit(state.copyWith(saveState: null, downloadProgress: 0));
      return;
    }
    ImageEnhancerServerPersistenceInfo? uploadInfo;
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
        final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final dirName = path_lib.dirname(origPath);
        final dstPath =
            "${dirName == "." ? "" : "$dirName/"}${path_lib.basenameWithoutExtension(origPath)}_enhanced_$epoch.jpg";
        uploadInfo = ImageEnhancerServerPersistenceInfo(
          baseUrl: account.url,
          endpoint: dstPath,
          headers: {
            "Authorization": AuthUtil.fromAccount(account).toHeaderValue(),
          },
        );
      }
    }
    unawaited(
      Workmanager().registerOneOffTask(
        "image-enhancer",
        "imageEnhancer",
        initialDelay: Duration.zero,
        existingWorkPolicy: ExistingWorkPolicy.append,
        inputData: ImageEnhancerTask.encodeArgument(
          type: taskType,
          platformIdentifier: uri.toString(),
          filename: file.name,
          uploadInfo: uploadInfo,
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
      ),
    );
    emit(
      state.copyWith(saveState: _ApplyState.background, downloadProgress: 0),
    );
  }

  void _onHelp(_Help ev, _Emitter emit) {
    _log.info(ev);
    launch(state.selectedMethod.helpUri.toString());
  }

  void _onSelectMethod(_SelectMethod ev, _Emitter emit) {
    _log.info(ev);
    emit(state.copyWith(selectedMethod: ev.value));
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  void _onSetApplyError(_SetApplyError ev, _Emitter emit) {
    _log.info(ev);
    emit(state.copyWith(applyError: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  final PrefController prefController;
  final Account account;
  final AnyFile file;

  var _isHandlingError = false;
}
