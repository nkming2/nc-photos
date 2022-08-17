import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/use_case/list_person.dart';

abstract class SearchLandingBlocEvent {
  const SearchLandingBlocEvent();
}

class SearchLandingBlocQuery extends SearchLandingBlocEvent {
  const SearchLandingBlocQuery(this.account);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "}";

  final Account account;
}

abstract class SearchLandingBlocState {
  const SearchLandingBlocState(this.account, this.persons);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "persons: List {length: ${persons.length}}, "
      "}";

  final Account? account;
  final List<Person> persons;
}

class SearchLandingBlocInit extends SearchLandingBlocState {
  SearchLandingBlocInit() : super(null, const []);
}

class SearchLandingBlocLoading extends SearchLandingBlocState {
  const SearchLandingBlocLoading(Account? account, List<Person> persons)
      : super(account, persons);
}

class SearchLandingBlocSuccess extends SearchLandingBlocState {
  const SearchLandingBlocSuccess(Account? account, List<Person> persons)
      : super(account, persons);
}

class SearchLandingBlocFailure extends SearchLandingBlocState {
  const SearchLandingBlocFailure(
      Account? account, List<Person> persons, this.exception)
      : super(account, persons);

  @override
  toString() => "$runtimeType {"
      "super: ${super.toString()}, "
      "exception: $exception, "
      "}";

  final Object exception;
}

class SearchLandingBloc
    extends Bloc<SearchLandingBlocEvent, SearchLandingBlocState> {
  SearchLandingBloc(this._c)
      : assert(require(_c)),
        assert(ListPerson.require(_c)),
        super(SearchLandingBlocInit()) {
    on<SearchLandingBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) => true;

  Future<void> _onEvent(SearchLandingBlocEvent event,
      Emitter<SearchLandingBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is SearchLandingBlocQuery) {
      await _onEventQuery(event, emit);
    }
  }

  Future<void> _onEventQuery(
      SearchLandingBlocQuery ev, Emitter<SearchLandingBlocState> emit) async {
    try {
      emit(SearchLandingBlocLoading(ev.account, state.persons));
      emit(SearchLandingBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(SearchLandingBlocFailure(ev.account, state.persons, e));
    }
  }

  Future<List<Person>> _query(SearchLandingBlocQuery ev) =>
      ListPerson(_c.withLocalRepo())(ev.account);

  final DiContainer _c;

  static final _log = Logger("bloc.search_landing.SearchLandingBloc");
}
