part of '../people_browser.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> implements BlocLogger {
  _Bloc({
    required this.account,
    required this.personsController,
  }) : super(_State.init()) {
    on<_LoadPersons>(_onLoad);
    on<_TransformItems>(_onTransformItems);
  }

  @override
  String get tag => _log.fullName;

  @override
  bool Function(dynamic, dynamic)? get shouldLog => null;

  Future<void> _onLoad(_LoadPersons ev, Emitter<_State> emit) {
    _log.info(ev);
    return emit.forEach<PersonStreamEvent>(
      personsController.stream,
      onData: (data) => state.copyWith(
        persons: data.data,
        isLoading: data.hasNext,
      ),
      onError: (e, stackTrace) {
        _log.severe("[_onLoad] Uncaught exception", e, stackTrace);
        return state.copyWith(
          isLoading: false,
          error: ExceptionEvent(e, stackTrace),
        );
      },
    );
  }

  Future<void> _onTransformItems(
      _TransformItems ev, Emitter<_State> emit) async {
    _log.info("[_onTransformItems] $ev");
    final transformed =
        ev.persons.sorted(_sorter).map((p) => _Item(p)).toList();
    emit(state.copyWith(transformedItems: transformed));
  }

  final Account account;
  final PersonsController personsController;
}

int _sorter(Person a, Person b) {
  final countCompare = (b.count ?? 0).compareTo(a.count ?? 0);
  if (countCompare == 0) {
    return a.name.compareTo(b.name);
  } else {
    return countCompare;
  }
}
