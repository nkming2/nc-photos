import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';

abstract class ListShareBlocEvent {
  const ListShareBlocEvent();
}

class ListShareBlocQuery extends ListShareBlocEvent {
  const ListShareBlocQuery(this.account, this.file);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "file: '${file.path}', "
        "}";
  }

  final Account account;
  final File file;
}

abstract class ListShareBlocState {
  const ListShareBlocState(this.account, this.file, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "file: '${file.path}', "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final File file;
  final List<Share> items;
}

class ListShareBlocInit extends ListShareBlocState {
  ListShareBlocInit() : super(null, File(path: ""), const []);
}

class ListShareBlocLoading extends ListShareBlocState {
  const ListShareBlocLoading(Account? account, File file, List<Share> items)
      : super(account, file, items);
}

class ListShareBlocSuccess extends ListShareBlocState {
  const ListShareBlocSuccess(Account? account, File file, List<Share> items)
      : super(account, file, items);
}

class ListShareBlocFailure extends ListShareBlocState {
  const ListShareBlocFailure(
      Account? account, File file, List<Share> items, this.exception)
      : super(account, file, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

/// List all shares from a given file
class ListShareBloc extends Bloc<ListShareBlocEvent, ListShareBlocState> {
  ListShareBloc() : super(ListShareBlocInit()) {
    on<ListShareBlocEvent>(_onEvent);
  }

  Future<void> _onEvent(
      ListShareBlocEvent event, Emitter<ListShareBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListShareBlocQuery) {
      await _onEventQuery(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListShareBlocQuery ev, Emitter<ListShareBlocState> emit) async {
    try {
      emit(ListShareBlocLoading(ev.account, ev.file, state.items));
      emit(ListShareBlocSuccess(ev.account, ev.file, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListShareBlocFailure(ev.account, ev.file, state.items, e));
    }
  }

  Future<List<Share>> _query(ListShareBlocQuery ev) {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    return shareRepo.list(ev.account, ev.file);
  }

  static final _log = Logger("bloc.list_share.ListShareBloc");
}
