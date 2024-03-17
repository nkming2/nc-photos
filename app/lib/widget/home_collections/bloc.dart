part of '../home_collections.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> with BlocLogger {
  _Bloc({
    required this.account,
    required this.controller,
    required this.prefController,
  }) : super(_State.init()) {
    on<_LoadCollections>(_onLoad);
    on<_ReloadCollections>(_onReload);
    on<_TransformItems>(_onTransformItems);

    on<_SetSelectedItems>(_onSetSelectedItems);
    on<_RemoveSelectedItems>(_onRemoveSelectedItems);

    on<_UpdateCollectionSort>(_onUpdateCollectionSort);
    on<_SetCollectionSort>(_onSetCollectionSort);
    on<_SetItemCount>(_onSetItemCount);

    on<_SetError>(_onSetError);

    _subscriptions.add(prefController.homeAlbumsSortChange.listen((event) {
      add(_UpdateCollectionSort(collection_util.CollectionSort.values[event]));
    }));
    _subscriptions.add(controller.stream.listen((event) {
      for (final s in _itemSubscriptions) {
        s.cancel();
      }
      _itemSubscriptions.clear();
      for (final d in event.data) {
        _itemSubscriptions.add(d.controller.countStream.listen((event) {
          if (event != null) {
            add(_SetItemCount(d.collection, event));
          }
        }));
      }
    }));
  }

  @override
  Future<void> close() {
    for (final s in _itemSubscriptions) {
      s.cancel();
    }
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }

  @override
  String get tag => _log.fullName;

  @override
  void onError(Object error, StackTrace stackTrace) {
    // we need this to prevent onError being triggered recursively
    if (!isClosed && !_isHandlingError) {
      _isHandlingError = true;
      try {
        add(_SetError(error, stackTrace));
      } catch (_) {}
      _isHandlingError = false;
    }
    super.onError(error, stackTrace);
  }

  Future<void> _onLoad(_LoadCollections ev, Emitter<_State> emit) async {
    _log.info(ev);
    return emit.forEach<CollectionStreamEvent>(
      controller.stream,
      onData: (data) => state.copyWith(
        collections: data.data.map((d) => d.collection).toList(),
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

  void _onReload(_ReloadCollections ev, Emitter<_State> emit) {
    _log.info(ev);
    unawaited(controller.reload());
  }

  Future<void> _onTransformItems(
      _TransformItems ev, Emitter<_State> emit) async {
    _log.info(ev);
    final transformed = _transformCollections(ev.collections, state.sort);
    emit(state.copyWith(transformedItems: transformed));
  }

  void _onSetSelectedItems(_SetSelectedItems ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(selectedItems: ev.items));
  }

  void _onRemoveSelectedItems(_RemoveSelectedItems ev, Emitter<_State> emit) {
    _log.info(ev);
    final selected = state.selectedItems;
    emit(state.copyWith(selectedItems: const {}));
    controller.remove(selected.map((e) => e.collection).toList());
  }

  void _onUpdateCollectionSort(_UpdateCollectionSort ev, Emitter<_State> emit) {
    _log.info(ev);
    if (ev.sort != state.sort) {
      final transformed = _transformCollections(state.collections, ev.sort);
      emit(state.copyWith(
        transformedItems: transformed,
        sort: ev.sort,
      ));
    }
  }

  void _onSetCollectionSort(_SetCollectionSort ev, Emitter<_State> emit) {
    _log.info(ev);
    prefController.setHomeAlbumsSort(ev.sort.index);
  }

  void _onSetItemCount(_SetItemCount ev, Emitter<_State> emit) {
    _log.info(ev);
    final next = Map.of(state.itemCounts);
    next[ev.collection.id] = ev.value;
    emit(state.copyWith(itemCounts: next));
  }

  void _onSetError(_SetError ev, Emitter<_State> emit) {
    _log.info(ev);
    emit(state.copyWith(error: ExceptionEvent(ev.error, ev.stackTrace)));
  }

  List<_Item> _transformCollections(
    List<Collection> collections,
    collection_util.CollectionSort sort,
  ) {
    final sorted = collections.sortedBy(sort);
    return sorted.map((c) => _Item(c)).toList();
  }

  final Account account;
  final CollectionsController controller;
  final PrefController prefController;

  final _subscriptions = <StreamSubscription>[];
  final _itemSubscriptions = <StreamSubscription>[];
  var _isHandlingError = false;
}
