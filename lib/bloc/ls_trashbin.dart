import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/ls_trashbin.dart';

abstract class LsTrashbinBlocEvent {
  const LsTrashbinBlocEvent();
}

class LsTrashbinBlocQuery extends LsTrashbinBlocEvent {
  const LsTrashbinBlocQuery(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

/// An external event has happened and may affect the state of this bloc
class _LsTrashbinBlocExternalEvent extends LsTrashbinBlocEvent {
  const _LsTrashbinBlocExternalEvent();

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }
}

abstract class LsTrashbinBlocState {
  const LsTrashbinBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final List<File> items;
}

class LsTrashbinBlocInit extends LsTrashbinBlocState {
  LsTrashbinBlocInit() : super(null, const []);
}

class LsTrashbinBlocLoading extends LsTrashbinBlocState {
  const LsTrashbinBlocLoading(Account? account, List<File> items)
      : super(account, items);
}

class LsTrashbinBlocSuccess extends LsTrashbinBlocState {
  const LsTrashbinBlocSuccess(Account? account, List<File> items)
      : super(account, items);
}

class LsTrashbinBlocFailure extends LsTrashbinBlocState {
  const LsTrashbinBlocFailure(
      Account? account, List<File> items, this.exception)
      : super(account, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class LsTrashbinBlocInconsistent extends LsTrashbinBlocState {
  const LsTrashbinBlocInconsistent(Account? account, List<File> items)
      : super(account, items);
}

class LsTrashbinBloc extends Bloc<LsTrashbinBlocEvent, LsTrashbinBlocState> {
  LsTrashbinBloc() : super(LsTrashbinBlocInit()) {
    _fileRemovedEventListener =
        AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
    _fileTrashbinRestoredEventListener =
        AppEventListener<FileTrashbinRestoredEvent>(
            _onFileTrashbinRestoredEvent);
    _fileRemovedEventListener.begin();
    _fileTrashbinRestoredEventListener.begin();

    _refreshThrottler = Throttler(
      onTriggered: (_) {
        add(const _LsTrashbinBlocExternalEvent());
      },
      logTag: "LsTrashbinBloc.refresh",
    );
  }

  static LsTrashbinBloc of(Account account) {
    final id = "${account.scheme}://${account.username}@${account.address}";
    try {
      _log.fine("[of] Resolving bloc for '$id'");
      return KiwiContainer().resolve<LsTrashbinBloc>("LsTrashbinBloc($id)");
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = LsTrashbinBloc();
      KiwiContainer()
          .registerInstance<LsTrashbinBloc>(bloc, name: "LsTrashbinBloc($id)");
      return bloc;
    }
  }

  @override
  mapEventToState(LsTrashbinBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is LsTrashbinBlocQuery) {
      yield* _onEventQuery(event);
    } else if (event is _LsTrashbinBlocExternalEvent) {
      yield* _onExternalEvent(event);
    }
  }

  Stream<LsTrashbinBlocState> _onEventQuery(LsTrashbinBlocQuery ev) async* {
    try {
      yield LsTrashbinBlocLoading(ev.account, state.items);
      yield LsTrashbinBlocSuccess(ev.account, await _query(ev));
    } catch (e) {
      _log.severe("[_onEventQuery] Exception while request", e);
      yield LsTrashbinBlocFailure(ev.account, state.items, e);
    }
  }

  Stream<LsTrashbinBlocState> _onExternalEvent(
      _LsTrashbinBlocExternalEvent ev) async* {
    yield LsTrashbinBlocInconsistent(state.account, state.items);
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is LsTrashbinBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (file_util.isTrash(ev.account, ev.file)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  void _onFileTrashbinRestoredEvent(FileTrashbinRestoredEvent ev) {
    if (state is LsTrashbinBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  Future<List<File>> _query(LsTrashbinBlocQuery ev) async {
    // caching contents in trashbin doesn't sounds useful
    const fileRepo = FileRepo(FileWebdavDataSource());
    final files = await LsTrashbin(fileRepo)(ev.account);
    return files.where((f) => file_util.isSupportedFormat(f)).toList();
  }

  late final AppEventListener<FileRemovedEvent> _fileRemovedEventListener;
  late final AppEventListener<FileTrashbinRestoredEvent>
      _fileTrashbinRestoredEventListener;

  late Throttler _refreshThrottler;

  static final _log = Logger("bloc.ls_trashbin.LsTrashbinBloc");
}
