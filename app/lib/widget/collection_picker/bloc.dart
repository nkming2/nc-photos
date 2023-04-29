part of '../collection_picker.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> implements BlocTag {
  _Bloc({
    required this.account,
    required this.controller,
  }) : super(_State.init()) {
    on<_LoadCollections>(_onLoad);
    on<_TransformItems>(_onTransformItems);
    on<_SelectCollection>(_onSelectCollection);
    on<_SetError>(_onSetError);
  }

  @override
  String get tag => _log.fullName;

  Future<void> _onLoad(_LoadCollections ev, Emitter<_State> emit) async {
    _log.info(ev);
    return emit.forEach<CollectionStreamEvent>(
      controller.stream,
      onData: (data) => state.copyWith(
        collections: data.data.map((e) => e.collection).toList(),
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

  void _onTransformItems(_TransformItems ev, Emitter<_State> emit) {
    _log.info(ev);
    final transformed = _transformCollections(ev.collections);
    emit(state.copyWith(transformedItems: transformed));
  }

  void _onSelectCollection(_SelectCollection ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(result: ev.collection));
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  List<_Item> _transformCollections(List<Collection> collections) {
    final sorted = collections
        .where((c) => CollectionAdapter.of(
                KiwiContainer().resolve<DiContainer>(), account, c)
            .isPermitted(CollectionCapability.manualItem))
        .sortedBy(collection_util.CollectionSort.dateDescending);
    return sorted.map((c) => _Item(c)).toList();
  }

  final Account account;
  final CollectionsController controller;
}
