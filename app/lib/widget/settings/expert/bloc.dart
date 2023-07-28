part of '../expert_settings.dart';

class _Error {
  const _Error(this.ev, [this.error, this.stackTrace]);

  final _Event ev;
  final Object? error;
  final StackTrace? stackTrace;
}

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc(DiContainer c)
      : _c = c,
        super(const _State()) {
    on<_ClearCacheDatabase>(_onClearCacheDatabase);
  }

  @override
  String get tag => _log.fullName;

  Stream<_Error> errorStream() => _errorStream.stream;

  Future<void> _onClearCacheDatabase(
      _ClearCacheDatabase ev, Emitter<_State> emit) async {
    try {
      await _c.sqliteDb.use((db) async {
        await db.truncate();
        final accounts = _c.pref.getAccounts3Or([]);
        for (final a in accounts) {
          await db.insertAccountOf(a);
        }
      });
      emit(state.copyWith(lastSuccessful: ev));
    } catch (e, stackTrace) {
      _log.shout("[_onClearCacheDatabase] Uncaught exception", e, stackTrace);
      _errorStream.add(_Error(ev, e, stackTrace));
    }
  }

  final DiContainer _c;
  final _errorStream = StreamController<_Error>.broadcast();
}
