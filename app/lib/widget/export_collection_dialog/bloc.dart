part of '../export_collection_dialog.dart';

@npLog
class _Bloc extends Bloc<_Event, _State> {
  _Bloc({
    required this.account,
    required this.collectionsController,
    required this.collection,
    required this.items,
  }) : super(_State.init()) {
    on<_FormEvent>(_onFormEvent);
  }

  Future<void> _onFormEvent(_FormEvent ev, Emitter<_State> emit) async {
    _log.info("$ev");
    if (ev is _SubmitName) {
      _onSubmitName(ev, emit);
    } else if (ev is _SubmitProvider) {
      _onSubmitProvider(ev, emit);
    } else if (ev is _SubmitForm) {
      await _onSubmitForm(ev, emit);
    }
  }

  void _onSubmitName(_SubmitName ev, Emitter<_State> emit) {
    emit(state.copyWith(
      formValue: state.formValue.copyWith(name: ev.value),
    ));
  }

  void _onSubmitProvider(_SubmitProvider ev, Emitter<_State> emit) {
    emit(state.copyWith(
      formValue: state.formValue.copyWith(provider: ev.value),
    ));
  }

  Future<void> _onSubmitForm(_SubmitForm ev, Emitter<_State> emit) async {
    emit(state.copyWith(isExporting: true));
    try {
      final exporter = CollectionExporter(account, collectionsController,
          collection, items, state.formValue.name);
      final Collection result;
      switch (state.formValue.provider) {
        case _ProviderOption.appAlbum:
          result = await exporter.asAlbum();
          break;
        case _ProviderOption.ncAlbum:
          result = await exporter.asNcAlbum();
          break;
      }
      emit(state.copyWith(result: result));
    } catch (e, stackTrace) {
      _log.severe("[_onSubmitForm] Failed while exporting", e, stackTrace);
    } finally {
      emit(state.copyWith(isExporting: false));
    }
  }

  final Account account;
  final CollectionsController collectionsController;
  final Collection collection;
  final List<CollectionItem> items;
}
