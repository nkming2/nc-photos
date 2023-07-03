import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/controller/account_pref_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/use_case/list_location_group.dart';
import 'package:nc_photos/use_case/person/list_person.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'search_landing.g.dart';

abstract class SearchLandingBlocEvent {
  const SearchLandingBlocEvent();
}

@toString
class SearchLandingBlocQuery extends SearchLandingBlocEvent {
  const SearchLandingBlocQuery(this.account, this.accountPrefController);

  @override
  String toString() => _$toString();

  final Account account;
  final AccountPrefController accountPrefController;
}

@toString
abstract class SearchLandingBlocState {
  const SearchLandingBlocState(this.account, this.persons, this.locations);

  @override
  String toString() => _$toString();

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

@toString
class SearchLandingBlocFailure extends SearchLandingBlocState {
  const SearchLandingBlocFailure(Account? account, List<Person> persons,
      LocationGroupResult locations, this.exception)
      : super(account, persons, locations);

  @override
  String toString() => _$toString();

  final Object exception;
}

@npLog
class SearchLandingBloc
    extends Bloc<SearchLandingBlocEvent, SearchLandingBlocState> {
  SearchLandingBloc(this._c) : super(SearchLandingBlocInit()) {
    on<SearchLandingBlocEvent>(_onEvent);
  }

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
      ListPerson(_c.withLocalRepo())(ev.account, ev.accountPrefController.raw)
          .last;

  Future<LocationGroupResult> _queryLocations(SearchLandingBlocQuery ev) =>
      ListLocationGroup(_c.withLocalRepo())(ev.account);

  final DiContainer _c;
}
