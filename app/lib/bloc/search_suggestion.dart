import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:tuple/tuple.dart';
import 'package:woozy_search/woozy_search.dart';

abstract class SearchSuggestionBlocEvent<T> {
  const SearchSuggestionBlocEvent();
}

class SearchSuggestionBlocUpdateItemsEvent<T>
    extends SearchSuggestionBlocEvent<T> {
  const SearchSuggestionBlocUpdateItemsEvent(this.items);

  @override
  toString() {
    return "$runtimeType {"
        "items: List {legth: ${items.length}}, "
        "}";
  }

  final List<T> items;
}

class SearchSuggestionBlocSearchEvent<T> extends SearchSuggestionBlocEvent<T> {
  const SearchSuggestionBlocSearchEvent(this.phrase);

  @override
  toString() {
    return "$runtimeType {"
        "phrase: '$phrase', "
        "}";
  }

  final CiString phrase;
}

abstract class SearchSuggestionBlocState<T> {
  const SearchSuggestionBlocState(this.results);

  @override
  toString() {
    return "$runtimeType {"
        "results: List {legth: ${results.length}}, "
        "}";
  }

  final List<T> results;
}

class SearchSuggestionBlocInit<T> extends SearchSuggestionBlocState<T> {
  const SearchSuggestionBlocInit() : super(const []);
}

class SearchSuggestionBlocLoading<T> extends SearchSuggestionBlocState<T> {
  const SearchSuggestionBlocLoading(List<T> results) : super(results);
}

class SearchSuggestionBlocSuccess<T> extends SearchSuggestionBlocState<T> {
  const SearchSuggestionBlocSuccess(List<T> results) : super(results);
}

class SearchSuggestionBloc<T>
    extends Bloc<SearchSuggestionBlocEvent, SearchSuggestionBlocState<T>> {
  SearchSuggestionBloc({
    required this.itemToKeywords,
  }) : super(SearchSuggestionBlocInit<T>()) {
    on<SearchSuggestionBlocEvent>(_onEvent);
  }

  Future<void> _onEvent(SearchSuggestionBlocEvent event,
      Emitter<SearchSuggestionBlocState<T>> emit) async {
    _log.info("[_onEvent] $event");
    if (event is SearchSuggestionBlocSearchEvent) {
      await _onEventSearch(event, emit);
    } else if (event is SearchSuggestionBlocUpdateItemsEvent<T>) {
      await _onEventUpdateItems(event, emit);
    }
  }

  Future<void> _onEventSearch(SearchSuggestionBlocSearchEvent ev,
      Emitter<SearchSuggestionBlocState<T>> emit) async {
    emit(SearchSuggestionBlocLoading(state.results));
    // doesn't work with upper case
    final results = _search.search(ev.phrase.toCaseInsensitiveString());
    if (kDebugMode) {
      final str = results.map((e) => "${e.score}: ${e.text}").join("\n");
      _log.info("[_onEventSearch] Search '${ev.phrase}':\n$str");
    }
    final matches = results
        .where((element) => element.score > 0)
        .map((e) {
          if (itemToKeywords(e.value as T)
              .any((k) => k.startsWith(ev.phrase))) {
            // prefer names that start exactly with the search phrase
            return Tuple2(e.score + 1, e.value as T);
          } else {
            return Tuple2(e.score, e.value as T);
          }
        })
        .sorted((a, b) => a.item1.compareTo(b.item1))
        .reversed
        .distinctIf(
          (a, b) => identical(a.item2, b.item2),
          (a) => a.item2.hashCode,
        )
        .map((e) => e.item2)
        .toList();
    emit(SearchSuggestionBlocSuccess(matches));
    _lastSearch = ev;
  }

  Future<void> _onEventUpdateItems(SearchSuggestionBlocUpdateItemsEvent<T> ev,
      Emitter<SearchSuggestionBlocState<T>> emit) async {
    _search.setEntries([]);
    for (final a in ev.items) {
      for (final k in itemToKeywords(a)) {
        _search.addEntry(k.toCaseInsensitiveString(), value: a);
      }
    }
    if (_lastSearch != null) {
      // search again
      await _onEventSearch(_lastSearch!, emit);
    }
  }

  final List<CiString> Function(T item) itemToKeywords;

  final _search = Woozy(limit: 5);
  SearchSuggestionBlocSearchEvent? _lastSearch;

  static final _log =
      Logger("bloc.album_search_suggestion.SearchSuggestionBloc");
}
