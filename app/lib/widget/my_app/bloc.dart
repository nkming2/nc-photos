part of '../my_app.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.prefController,
  }) : super(_State(
          language: prefController.language.value,
          isDarkTheme: prefController.isDarkTheme.value,
          isFollowSystemTheme: prefController.isFollowSystemTheme.value,
          isUseBlackInDarkTheme: prefController.isUseBlackInDarkTheme.value,
          seedColor: prefController.seedColor.value?.value,
        )) {
    on<_Init>(_onInit);
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onInit(_Init ev, Emitter<_State> emit) async {
    _log.info(ev);
    await Future.wait([
      emit.forEachIgnoreError<language_util.AppLanguage>(
        prefController.language,
        onData: (data) => state.copyWith(language: data),
      ),
      emit.forEachIgnoreError<bool>(
        prefController.isDarkTheme,
        onData: (data) => state.copyWith(isDarkTheme: data),
      ),
      emit.forEachIgnoreError<bool>(
        prefController.isFollowSystemTheme,
        onData: (data) => state.copyWith(isFollowSystemTheme: data),
      ),
      emit.forEachIgnoreError<bool>(
        prefController.isUseBlackInDarkTheme,
        onData: (data) => state.copyWith(isUseBlackInDarkTheme: data),
      ),
      emit.forEachIgnoreError<Color?>(
        prefController.seedColor,
        onData: (data) => state.copyWith(seedColor: data?.value),
      ),
    ]);
  }

  final PrefController prefController;
}
