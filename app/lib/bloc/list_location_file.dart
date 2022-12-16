import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/list_location_file.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'list_location_file.g.dart';

abstract class ListLocationFileBlocEvent {
  const ListLocationFileBlocEvent();
}

@toString
class ListLocationFileBlocQuery extends ListLocationFileBlocEvent {
  const ListLocationFileBlocQuery(this.account, this.place, this.countryCode);

  @override
  String toString() => _$toString();

  final Account account;
  final String? place;
  final String countryCode;
}

/// An external event has happened and may affect the state of this bloc
@toString
class _ListLocationFileBlocExternalEvent extends ListLocationFileBlocEvent {
  const _ListLocationFileBlocExternalEvent();

  @override
  String toString() => _$toString();
}

@toString
abstract class ListLocationFileBlocState {
  const ListLocationFileBlocState(this.account, this.items);

  @override
  String toString() => _$toString();

  final Account? account;
  final List<File> items;
}

class ListLocationFileBlocInit extends ListLocationFileBlocState {
  ListLocationFileBlocInit() : super(null, const []);
}

class ListLocationFileBlocLoading extends ListLocationFileBlocState {
  const ListLocationFileBlocLoading(Account? account, List<File> items)
      : super(account, items);
}

class ListLocationFileBlocSuccess extends ListLocationFileBlocState {
  const ListLocationFileBlocSuccess(Account? account, List<File> items)
      : super(account, items);
}

@toString
class ListLocationFileBlocFailure extends ListLocationFileBlocState {
  const ListLocationFileBlocFailure(
      Account? account, List<File> items, this.exception)
      : super(account, items);

  @override
  String toString() => _$toString();

  final Object exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ListLocationFileBlocInconsistent extends ListLocationFileBlocState {
  const ListLocationFileBlocInconsistent(Account? account, List<File> items)
      : super(account, items);
}

/// List all files associated with a specific tag
@npLog
class ListLocationFileBloc
    extends Bloc<ListLocationFileBlocEvent, ListLocationFileBlocState> {
  ListLocationFileBloc(this._c)
      : assert(require(_c)),
        assert(ListLocationFile.require(_c)),
        super(ListLocationFileBlocInit()) {
    _fileRemovedEventListener.begin();

    on<ListLocationFileBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.taggedFileRepo);

  @override
  close() {
    _fileRemovedEventListener.end();
    return super.close();
  }

  Future<void> _onEvent(ListLocationFileBlocEvent event,
      Emitter<ListLocationFileBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListLocationFileBlocQuery) {
      await _onEventQuery(event, emit);
    } else if (event is _ListLocationFileBlocExternalEvent) {
      await _onExternalEvent(event, emit);
    }
  }

  Future<void> _onEventQuery(ListLocationFileBlocQuery ev,
      Emitter<ListLocationFileBlocState> emit) async {
    try {
      emit(ListLocationFileBlocLoading(ev.account, state.items));
      emit(ListLocationFileBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListLocationFileBlocFailure(ev.account, state.items, e));
    }
  }

  Future<void> _onExternalEvent(_ListLocationFileBlocExternalEvent ev,
      Emitter<ListLocationFileBlocState> emit) async {
    emit(ListLocationFileBlocInconsistent(state.account, state.items));
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ListLocationFileBlocInit) {
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

  Future<List<File>> _query(ListLocationFileBlocQuery ev) async {
    final files = <File>[];
    for (final r in ev.account.roots) {
      final dir = File(path: file_util.unstripPath(ev.account, r));
      files.addAll(await ListLocationFile(_c)(
          ev.account, dir, ev.place, ev.countryCode));
    }
    return files.where((f) => file_util.isSupportedFormat(f)).toList();
  }

  bool _isFileOfInterest(File file) {
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
      add(const _ListLocationFileBlocExternalEvent());
    },
    logTag: "ListLocationFileBloc.refresh",
  );
}
