import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/use_case/list_person.dart';

abstract class ListPersonBlocEvent {
  const ListPersonBlocEvent();
}

class ListPersonBlocQuery extends ListPersonBlocEvent {
  const ListPersonBlocQuery(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

abstract class ListPersonBlocState {
  const ListPersonBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final List<Person> items;
}

class ListPersonBlocInit extends ListPersonBlocState {
  ListPersonBlocInit() : super(null, const []);
}

class ListPersonBlocLoading extends ListPersonBlocState {
  const ListPersonBlocLoading(Account? account, List<Person> items)
      : super(account, items);
}

class ListPersonBlocSuccess extends ListPersonBlocState {
  const ListPersonBlocSuccess(Account? account, List<Person> items)
      : super(account, items);
}

class ListPersonBlocFailure extends ListPersonBlocState {
  const ListPersonBlocFailure(
      Account? account, List<Person> items, this.exception)
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

/// List all people recognized in an account
class ListPersonBloc extends Bloc<ListPersonBlocEvent, ListPersonBlocState> {
  ListPersonBloc(this._c)
      : assert(require(_c)),
        assert(ListPerson.require(_c)),
        super(ListPersonBlocInit()) {
    on<ListPersonBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) => true;

  Future<void> _onEvent(
      ListPersonBlocEvent event, Emitter<ListPersonBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListPersonBlocQuery) {
      await _onEventQuery(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListPersonBlocQuery ev, Emitter<ListPersonBlocState> emit) async {
    try {
      emit(ListPersonBlocLoading(ev.account, state.items));
      emit(ListPersonBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListPersonBlocFailure(ev.account, state.items, e));
    }
  }

  Future<List<Person>> _query(ListPersonBlocQuery ev) =>
      ListPerson(_c)(ev.account);

  final DiContainer _c;

  static final _log = Logger("bloc.list_person.ListPersonBloc");
}
