import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:tuple/tuple.dart';
import 'package:woozy_search/woozy_search.dart';

abstract class AlbumSearchSuggestionBlocEvent {
  const AlbumSearchSuggestionBlocEvent();
}

class AlbumSearchSuggestionBlocUpdateItemsEvent
    extends AlbumSearchSuggestionBlocEvent {
  const AlbumSearchSuggestionBlocUpdateItemsEvent(this.albums);

  @override
  toString() {
    return "$runtimeType {"
        "albums: List {legth: ${albums.length}}, "
        "}";
  }

  final List<Album> albums;
}

class AlbumSearchSuggestionBlocSearchEvent
    extends AlbumSearchSuggestionBlocEvent {
  const AlbumSearchSuggestionBlocSearchEvent(this.phrase);

  @override
  toString() {
    return "$runtimeType {"
        "phrase: '$phrase', "
        "}";
  }

  final String phrase;
}

abstract class AlbumSearchSuggestionBlocState {
  const AlbumSearchSuggestionBlocState(this.results);

  @override
  toString() {
    return "$runtimeType {"
        "results: List {legth: ${results.length}}, "
        "}";
  }

  final List<Album> results;
}

class AlbumSearchSuggestionBlocInit extends AlbumSearchSuggestionBlocState {
  const AlbumSearchSuggestionBlocInit() : super(const []);
}

class AlbumSearchSuggestionBlocSuccess extends AlbumSearchSuggestionBlocState {
  const AlbumSearchSuggestionBlocSuccess(List<Album> results) : super(results);
}

class AlbumSearchSuggestionBloc extends Bloc<AlbumSearchSuggestionBlocEvent,
    AlbumSearchSuggestionBlocState> {
  AlbumSearchSuggestionBloc() : super(AlbumSearchSuggestionBlocInit());

  @override
  mapEventToState(AlbumSearchSuggestionBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is AlbumSearchSuggestionBlocSearchEvent) {
      yield* _onEventSearch(event);
    } else if (event is AlbumSearchSuggestionBlocUpdateItemsEvent) {
      yield* _onEventUpdateItems(event);
    }
  }

  Stream<AlbumSearchSuggestionBlocState> _onEventSearch(
      AlbumSearchSuggestionBlocSearchEvent ev) async* {
    // doesn't work with upper case
    final results = _search.search(ev.phrase.toLowerCase());
    if (kDebugMode) {
      final str = results.map((e) => "${e.score}: ${e.text}").join("\n");
      _log.info("[_onEventSearch] Search '${ev.phrase}':\n$str");
    }
    final matches = results
        .where((element) => element.score > 0)
        .map((e) {
          if ((e.value as Album)
              .name
              .toLowerCase()
              .startsWith(ev.phrase.toLowerCase())) {
            // prefer names that start exactly with the search phrase
            return Tuple2(e.score + 1, e.value as Album);
          } else {
            return Tuple2(e.score, e.value as Album);
          }
        })
        .sorted((a, b) {
          return a.item1.compareTo(b.item1);
        })
        .reversed
        .map((e) => e.item2)
        .toList();
    yield AlbumSearchSuggestionBlocSuccess(matches);
    _lastSearch = ev;
  }

  Stream<AlbumSearchSuggestionBlocState> _onEventUpdateItems(
      AlbumSearchSuggestionBlocUpdateItemsEvent ev) async* {
    _search.setEntries([]);
    for (final a in ev.albums) {
      _search.addEntry(a.name, value: a);
    }
    if (_lastSearch != null) {
      // search again
      yield* _onEventSearch(_lastSearch!);
    }
  }

  final _search = Woozy(limit: 5);
  AlbumSearchSuggestionBlocSearchEvent? _lastSearch;

  static final _log =
      Logger("bloc.album_search_suggestion.AlbumSearchSuggestionBloc");
}
