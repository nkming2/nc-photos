import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/list_location_group.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'list_location.g.dart';

abstract class ListLocationBlocEvent {
  const ListLocationBlocEvent();
}

@toString
class ListLocationBlocQuery extends ListLocationBlocEvent {
  const ListLocationBlocQuery(this.account);

  @override
  String toString() => _$toString();

  final Account account;
}

/// An external event has happened and may affect the state of this bloc
@toString
class _ListLocationBlocExternalEvent extends ListLocationBlocEvent {
  const _ListLocationBlocExternalEvent();

  @override
  String toString() => _$toString();
}

@toString
abstract class ListLocationBlocState {
  const ListLocationBlocState(this.account, this.result);

  @override
  String toString() => _$toString();

  final Account? account;
  final LocationGroupResult result;
}

class ListLocationBlocInit extends ListLocationBlocState {
  ListLocationBlocInit()
      : super(null, const LocationGroupResult([], [], [], []));
}

class ListLocationBlocLoading extends ListLocationBlocState {
  const ListLocationBlocLoading(Account? account, LocationGroupResult result)
      : super(account, result);
}

class ListLocationBlocSuccess extends ListLocationBlocState {
  const ListLocationBlocSuccess(Account? account, LocationGroupResult result)
      : super(account, result);
}

@toString
class ListLocationBlocFailure extends ListLocationBlocState {
  const ListLocationBlocFailure(
      Account? account, LocationGroupResult result, this.exception)
      : super(account, result);

  @override
  String toString() => _$toString();

  final Object exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ListLocationBlocInconsistent extends ListLocationBlocState {
  const ListLocationBlocInconsistent(
      Account? account, LocationGroupResult result)
      : super(account, result);
}

/// List all files associated with a specific tag
@npLog
class ListLocationBloc
    extends Bloc<ListLocationBlocEvent, ListLocationBlocState> {
  ListLocationBloc(this._c)
      : assert(require(_c)),
        super(ListLocationBlocInit()) {
    _fileRemovedEventListener.begin();

    on<ListLocationBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.taggedFileRepo);

  @override
  close() {
    _fileRemovedEventListener.end();
    return super.close();
  }

  Future<void> _onEvent(
      ListLocationBlocEvent event, Emitter<ListLocationBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListLocationBlocQuery) {
      await _onEventQuery(event, emit);
    } else if (event is _ListLocationBlocExternalEvent) {
      await _onExternalEvent(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListLocationBlocQuery ev, Emitter<ListLocationBlocState> emit) async {
    try {
      emit(ListLocationBlocLoading(ev.account, state.result));
      emit(ListLocationBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListLocationBlocFailure(ev.account, state.result, e));
    }
  }

  Future<void> _onExternalEvent(_ListLocationBlocExternalEvent ev,
      Emitter<ListLocationBlocState> emit) async {
    emit(ListLocationBlocInconsistent(state.account, state.result));
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ListLocationBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (_isFileOfInterest(ev.file)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  Future<LocationGroupResult> _query(ListLocationBlocQuery ev) =>
      ListLocationGroup(_c.withLocalRepo())(ev.account);

  bool _isFileOfInterest(FileDescriptor file) {
    if (!file_util.isSupportedFormat(file)) {
      return false;
    }

    for (final r in state.account?.roots ?? []) {
      final dir = File(path: file_util.unstripPath(state.account!, r));
      if (file_util.isUnderDir(file, dir)) {
        return true;
      }
    }
    return false;
  }

  final DiContainer _c;

  late final _fileRemovedEventListener =
      AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);

  late final _refreshThrottler = Throttler(
    onTriggered: (_) {
      add(const _ListLocationBlocExternalEvent());
    },
    logTag: "ListLocationBloc.refresh",
  );
}
