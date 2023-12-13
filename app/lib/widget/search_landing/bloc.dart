part of '../search_landing.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.account,
    required this.personsController,
    required this.placesController,
  }) : super(_State.init()) {
    on<_LoadPersons>(_onLoadPersons);
    on<_TransformPersonItems>(_onTransformPersonItems);
    on<_LoadPlaces>(_onLoadPlaces);
    on<_TransformPlaceItems>(_onTransformPlaceItems);
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onLoadPersons(_LoadPersons ev, Emitter<_State> emit) {
    _log.info(ev);
    return emit.forEach<PersonStreamEvent>(
      personsController.stream,
      onData: (data) => state.copyWith(
        persons: data.data,
        isPersonsLoading: data.hasNext,
      ),
      onError: (e, stackTrace) {
        _log.severe("[_onLoadPersons] Uncaught exception", e, stackTrace);
        return state.copyWith(
          isPersonsLoading: false,
          error: ExceptionEvent(e, stackTrace),
        );
      },
    );
  }

  Future<void> _onTransformPersonItems(
      _TransformPersonItems ev, Emitter<_State> emit) async {
    _log.info(ev);
    final transformed = ev.persons
        .sorted((a, b) {
          final countCompare = (b.count ?? 0).compareTo(a.count ?? 0);
          if (countCompare == 0) {
            return a.name.compareTo(b.name);
          } else {
            return countCompare;
          }
        })
        .take(10)
        .map(_PersonItem.new)
        .toList();
    emit(state.copyWith(transformedPersonItems: transformed));
  }

  Future<void> _onLoadPlaces(_LoadPlaces ev, Emitter<_State> emit) {
    _log.info(ev);
    return emit.forEach<PlaceStreamEvent>(
      placesController.stream,
      onData: (data) => state.copyWith(
        places: data.data,
        isPlacesLoading: data.hasNext,
      ),
      onError: (e, stackTrace) {
        _log.severe("[_onLoadPlaces] Uncaught exception", e, stackTrace);
        return state.copyWith(
          isPlacesLoading: false,
          error: ExceptionEvent(e, stackTrace),
        );
      },
    );
  }

  Future<void> _onTransformPlaceItems(
      _TransformPlaceItems ev, Emitter<_State> emit) async {
    _log.info(ev);
    final transformed = ev.places.name
        .sorted((a, b) {
          final compare = b.count.compareTo(a.count);
          if (compare == 0) {
            return a.place.compareTo(b.place);
          } else {
            return compare;
          }
        })
        .take(10)
        .map((e) => _PlaceItem(account: account, place: e))
        .toList();
    emit(state.copyWith(transformedPlaceItems: transformed));
  }

  final Account account;
  final PersonsController personsController;
  final PlacesController placesController;
}
