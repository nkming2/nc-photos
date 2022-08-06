import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/use_case/list_person.dart';
import 'package:nc_photos/use_case/list_tag.dart';
import 'package:tuple/tuple.dart';
import 'package:woozy_search/woozy_search.dart';

abstract class HomeSearchResult {}

class HomeSearchAlbumResult implements HomeSearchResult {
  const HomeSearchAlbumResult(this.album);

  @override
  toString() => "$runtimeType {"
      "album: $album, "
      "}";

  final Album album;
}

class HomeSearchTagResult implements HomeSearchResult {
  const HomeSearchTagResult(this.tag);

  @override
  toString() => "$runtimeType {"
      "tag: $tag, "
      "}";

  final Tag tag;
}

class HomeSearchPersonResult implements HomeSearchResult {
  const HomeSearchPersonResult(this.person);

  @override
  toString() => "$runtimeType {"
      "person: $person, "
      "}";

  final Person person;
}

abstract class HomeSearchSuggestionBlocEvent {
  const HomeSearchSuggestionBlocEvent();
}

class HomeSearchSuggestionBlocPreloadData
    extends HomeSearchSuggestionBlocEvent {
  const HomeSearchSuggestionBlocPreloadData();

  @override
  toString() => "$runtimeType {"
      "}";
}

class HomeSearchSuggestionBlocSearch extends HomeSearchSuggestionBlocEvent {
  const HomeSearchSuggestionBlocSearch(this.phrase);

  @override
  toString() => "$runtimeType {"
      "phrase: '$phrase', "
      "}";

  final CiString phrase;
}

abstract class HomeSearchSuggestionBlocState {
  const HomeSearchSuggestionBlocState(this.results);

  @override
  toString() => "$runtimeType {"
      "results: List {legth: ${results.length}}, "
      "}";

  final List<HomeSearchResult> results;
}

class HomeSearchSuggestionBlocInit extends HomeSearchSuggestionBlocState {
  const HomeSearchSuggestionBlocInit() : super(const []);
}

class HomeSearchSuggestionBlocLoading extends HomeSearchSuggestionBlocState {
  const HomeSearchSuggestionBlocLoading(List<HomeSearchResult> results)
      : super(results);
}

class HomeSearchSuggestionBlocSuccess extends HomeSearchSuggestionBlocState {
  const HomeSearchSuggestionBlocSuccess(List<HomeSearchResult> results)
      : super(results);
}

class HomeSearchSuggestionBlocFailure extends HomeSearchSuggestionBlocState {
  const HomeSearchSuggestionBlocFailure(
      List<HomeSearchTagResult> results, this.exception)
      : super(results);

  @override
  toString() => "$runtimeType {"
      "super: ${super.toString()}, "
      "exception: $exception, "
      "}";

  final Object exception;
}

class HomeSearchSuggestionBloc
    extends Bloc<HomeSearchSuggestionBlocEvent, HomeSearchSuggestionBlocState> {
  HomeSearchSuggestionBloc(this.account)
      : super(const HomeSearchSuggestionBlocInit()) {
    final c = KiwiContainer().resolve<DiContainer>();
    assert(require(c));
    assert(ListTag.require(c));
    _c = c.withLocalRepo();

    on<HomeSearchSuggestionBlocEvent>(_onEvent);

    add(const HomeSearchSuggestionBlocPreloadData());
  }

  static bool require(DiContainer c) => true;

  Future<void> _onEvent(HomeSearchSuggestionBlocEvent event,
      Emitter<HomeSearchSuggestionBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is HomeSearchSuggestionBlocSearch) {
      await _onEventSearch(event, emit);
    } else if (event is HomeSearchSuggestionBlocPreloadData) {
      await _onEventPreloadData(event, emit);
    }
  }

  Future<void> _onEventSearch(HomeSearchSuggestionBlocSearch ev,
      Emitter<HomeSearchSuggestionBlocState> emit) async {
    if (ev.phrase.raw.isEmpty) {
      emit(const HomeSearchSuggestionBlocSuccess([]));
      return;
    }

    emit(HomeSearchSuggestionBlocLoading(state.results));
    // doesn't work with upper case
    final results = _search.search(ev.phrase.toCaseInsensitiveString());
    if (kDebugMode) {
      final str = results.map((e) => "${e.score}: ${e.text}").join("\n");
      _log.fine("[_onEventSearch] Search '${ev.phrase}':\n$str");
    }
    final matches = results
        .where((element) => element.score > 0)
        .map((e) {
          if (e.value!.toKeywords().any((k) => k.startsWith(ev.phrase))) {
            // prefer names that start exactly with the search phrase
            return Tuple2(e.score + 1, e.value);
          } else {
            return Tuple2(e.score, e.value);
          }
        })
        .sorted((a, b) => b.item1.compareTo(a.item1))
        .distinctIf(
          (a, b) => identical(a.item2, b.item2),
          (a) => a.item2.hashCode,
        )
        .map((e) => e.item2!.toResult())
        .toList();
    emit(HomeSearchSuggestionBlocSuccess(matches));
  }

  Future<void> _onEventPreloadData(HomeSearchSuggestionBlocPreloadData ev,
      Emitter<HomeSearchSuggestionBlocState> emit) async {
    final product = <_Searcheable>[];
    try {
      final albums = await ListAlbum(_c)(account)
          .where((event) => event is Album)
          .toList();
      product.addAll(albums.map((a) => _AlbumSearcheable(a)));
      _log.info("[_onEventPreloadData] Loaded ${albums.length} albums");
    } catch (e) {
      _log.warning("[_onEventPreloadData] Failed while ListAlbum", e);
    }
    try {
      final tags = await ListTag(_c)(account);
      product.addAll(tags.map((t) => _TagSearcheable(t)));
      _log.info("[_onEventPreloadData] Loaded ${tags.length} tags");
    } catch (e) {
      _log.warning("[_onEventPreloadData] Failed while ListTag", e);
    }
    try {
      final persons = await ListPerson(_c)(account);
      product.addAll(persons.map((t) => _PersonSearcheable(t)));
      _log.info("[_onEventPreloadData] Loaded ${persons.length} people");
    } catch (e) {
      _log.warning("[_onEventPreloadData] Failed while ListPerson", e);
    }

    _setSearchItems(product);
  }

  void _setSearchItems(List<_Searcheable> searcheables) {
    _search.setEntries([]);
    for (final s in searcheables) {
      for (final k in s.toKeywords()) {
        _search.addEntry(k.toCaseInsensitiveString(), value: s);
      }
    }
  }

  final Account account;
  late final DiContainer _c;

  final _search = Woozy<_Searcheable>(limit: 10);

  static final _log =
      Logger("bloc.album_search_suggestion.HomeSearchSuggestionBloc");
}

abstract class _Searcheable {
  List<CiString> toKeywords();
  HomeSearchResult toResult();
}

class _AlbumSearcheable implements _Searcheable {
  const _AlbumSearcheable(this.album);

  @override
  toKeywords() => [album.name.toCi()];

  @override
  toResult() => HomeSearchAlbumResult(album);

  final Album album;
}

class _TagSearcheable implements _Searcheable {
  const _TagSearcheable(this.tag);

  @override
  toKeywords() => [tag.displayName.toCi()];

  @override
  toResult() => HomeSearchTagResult(tag);

  final Tag tag;
}

class _PersonSearcheable implements _Searcheable {
  const _PersonSearcheable(this.person);

  @override
  toKeywords() => [person.name.toCi()];

  @override
  toResult() => HomeSearchPersonResult(person);

  final Person person;
}
