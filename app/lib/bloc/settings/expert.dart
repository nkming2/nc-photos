import 'dart:async';

import 'package:copy_with/copy_with.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'expert.g.dart';

@genCopyWith
@toString
class ExpertSettingsState {
  const ExpertSettingsState({
    this.lastSuccessful,
  });

  @override
  String toString() => _$toString();

  final ExpertSettingsEvent? lastSuccessful;
}

abstract class ExpertSettingsEvent {
  const ExpertSettingsEvent();
}

@toString
class ExpertSettingsClearCacheDatabase extends ExpertSettingsEvent {
  ExpertSettingsClearCacheDatabase();

  @override
  String toString() => _$toString();
}

class ExpertSettingsError {
  const ExpertSettingsError(this.ev, [this.error, this.stackTrace]);

  final ExpertSettingsEvent ev;
  final Object? error;
  final StackTrace? stackTrace;
}

@npLog
class ExpertSettingsBloc
    extends Bloc<ExpertSettingsEvent, ExpertSettingsState> {
  ExpertSettingsBloc(DiContainer c)
      : _c = c,
        super(const ExpertSettingsState()) {
    on<ExpertSettingsClearCacheDatabase>(_onClearCacheDatabase);
  }

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.pref) && DiContainer.has(c, DiType.sqliteDb);

  Stream<ExpertSettingsError> errorStream() => _errorStream.stream;

  Future<void> _onClearCacheDatabase(ExpertSettingsClearCacheDatabase ev,
      Emitter<ExpertSettingsState> emit) async {
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
      _errorStream.add(ExpertSettingsError(ev, e, stackTrace));
    }
  }

  final DiContainer _c;
  final _errorStream = StreamController<ExpertSettingsError>.broadcast();
}
