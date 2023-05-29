part of '../developer_settings.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> {
  _Bloc(DiContainer c)
      : _c = c,
        super(const _State()) {
    on<_VacuumDb>(_onVacuumDb);
    on<_ExportDb>(_onExportDb);
    on<_ClearCertWhitelist>(_onClearCertWhitelist);

    on<_SetError>(_onSetError);
  }

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

  Future<void> _onVacuumDb(_VacuumDb ev, Emitter<_State> emit) async {
    await _c.sqliteDb.useNoTransaction((db) async {
      await db.customStatement("VACUUM;");
    });
    emit(state.copyWith(message: StateMessage("Finished successfully")));
  }

  Future<void> _onExportDb(_ExportDb ev, Emitter<_State> emit) async {
    await platform.exportSqliteDb(_c.sqliteDb);
    emit(state.copyWith(message: StateMessage("Finished successfully")));
  }

  Future<void> _onClearCertWhitelist(
      _ClearCertWhitelist ev, Emitter<_State> emit) async {
    await SelfSignedCertManager().clearWhitelist();
    emit(state.copyWith(message: StateMessage("Finished successfully")));
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info("$ev");
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  final DiContainer _c;

  var _isHandlingError = false;
}
