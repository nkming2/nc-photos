part of '../photos_settings.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.prefController,
    required this.accountPrefController,
  }) : super(_State(
          isEnableMemories: accountPrefController.isEnableMemoryAlbumValue,
          isPhotosTabSortByName: prefController.isPhotosTabSortByNameValue,
          memoriesRange: prefController.memoriesRangeValue,
        )) {
    on<_Init>(_onInit);
    on<_SetEnableMemories>(_onSetEnableMemories);
    on<_SetMemoriesRange>(_onSetMemoriesRange);
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onInit(_Init ev, Emitter<_State> emit) async {
    _log.info(ev);
    await Future.wait([
      emit.forEach<bool>(
        accountPrefController.isEnableMemoryAlbumChange,
        onData: (data) => state.copyWith(isEnableMemories: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
      emit.forEach<bool>(
        prefController.isPhotosTabSortByNameChange,
        onData: (data) => state.copyWith(isPhotosTabSortByName: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
      emit.forEach<int>(
        prefController.memoriesRangeChange,
        onData: (data) => state.copyWith(memoriesRange: data),
        onError: (e, stackTrace) {
          _log.severe("[_onInit] Uncaught exception", e, stackTrace);
          return state.copyWith(error: ExceptionEvent(e, stackTrace));
        },
      ),
    ]);
  }

  void _onSetEnableMemories(_SetEnableMemories ev, Emitter<_State> emit) {
    _log.info(ev);
    accountPrefController.setEnableMemoryAlbum(ev.value);
  }

  void _onSetMemoriesRange(_SetMemoriesRange ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setMemoriesRange(ev.value);
  }

  final PrefController prefController;
  final AccountPrefController accountPrefController;
}
