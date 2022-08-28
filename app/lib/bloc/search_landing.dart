import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/use_case/list_location_group.dart';
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
  const SearchLandingBlocState(this.account, this.persons, this.locations);

  @override
  toString() => "$runtimeType {"
      "account: $account, "
      "persons: List {length: ${persons.length}}, "
      "locations: $locations, "
      "}";

  final Account? account;
  final List<Person> persons;
  final LocationGroupResult locations;
}

class SearchLandingBlocInit extends SearchLandingBlocState {
  SearchLandingBlocInit()
      : super(null, const [], const LocationGroupResult([], [], [], []));
}

class SearchLandingBlocLoading extends SearchLandingBlocState {
  const SearchLandingBlocLoading(
      Account? account, List<Person> persons, LocationGroupResult locations)
      : super(account, persons, locations);
}

class SearchLandingBlocSuccess extends SearchLandingBlocState {
  const SearchLandingBlocSuccess(
      Account? account, List<Person> persons, LocationGroupResult locations)
      : super(account, persons, locations);
}

class SearchLandingBlocFailure extends SearchLandingBlocState {
  const SearchLandingBlocFailure(Account? account, List<Person> persons,
      LocationGroupResult locations, this.exception)
      : super(account, persons, locations);

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
      emit(
          SearchLandingBlocLoading(ev.account, state.persons, state.locations));

      List<Person>? persons;
      try {
        persons = await _queryPeople(ev);
      } catch (e, stackTrace) {
        _log.shout("[_onEventQuery] Failed while _queryPeople", e, stackTrace);
      }

      LocationGroupResult? locations;
      try {
        locations = await _queryLocations(ev);
      } catch (e, stackTrace) {
        _log.shout(
            "[_onEventQuery] Failed while _queryLocations", e, stackTrace);
      }

      emit(SearchLandingBlocSuccess(ev.account, persons ?? [],
          locations ?? const LocationGroupResult([], [], [], [])));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(SearchLandingBlocFailure(
          ev.account, state.persons, state.locations, e));
    }
  }

  Future<List<Person>> _queryPeople(SearchLandingBlocQuery ev) =>
      ListPerson(_c.withLocalRepo())(ev.account);

  Future<LocationGroupResult> _queryLocations(SearchLandingBlocQuery ev) =>
      ListLocationGroup(_c.withLocalRepo())(ev.account);

  final DiContainer _c;

  static final _log = Logger("bloc.search_landing.SearchLandingBloc");
}
