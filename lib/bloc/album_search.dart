import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/iterable_extension.dart';

abstract class AlbumSearchBlocEvent {
  const AlbumSearchBlocEvent();
}

class AlbumSearchBlocSearchEvent extends AlbumSearchBlocEvent {
  const AlbumSearchBlocSearchEvent(this.phrase);

  @override
  toString() {
    return "$runtimeType {"
        "phrase: '$phrase', "
        "}";
  }

  final String phrase;
}

class AlbumSearchBlocUpdateItemsEvent extends AlbumSearchBlocEvent {
  const AlbumSearchBlocUpdateItemsEvent(this.albums);

  @override
  toString() {
    return "$runtimeType {"
        "albums: List {legth: ${albums.length}}, "
        "}";
  }

  final List<Album> albums;
}

abstract class AlbumSearchBlocState {
  const AlbumSearchBlocState(this.results);

  @override
  toString() {
    return "$runtimeType {"
        "results: List {legth: ${results.length}}, "
        "}";
  }

  final List<Album> results;
}

class AlbumSearchBlocInit extends AlbumSearchBlocState {
  const AlbumSearchBlocInit() : super(const []);
}

class AlbumSearchBlocSuccess extends AlbumSearchBlocState {
  const AlbumSearchBlocSuccess(List<Album> results) : super(results);
}

class AlbumSearchBloc extends Bloc<AlbumSearchBlocEvent, AlbumSearchBlocState> {
  AlbumSearchBloc() : super(const AlbumSearchBlocInit());

  @override
  mapEventToState(AlbumSearchBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is AlbumSearchBlocSearchEvent) {
      yield* _onEventSearch(event);
    } else if (event is AlbumSearchBlocUpdateItemsEvent) {
      yield* _onEventUpdateItems(event);
    }
  }

  Stream<AlbumSearchBlocState> _onEventSearch(
      AlbumSearchBlocSearchEvent ev) async* {
    final matches = _albums
        .where((element) =>
            element.name.toLowerCase().contains(ev.phrase.toLowerCase()))
        .sorted((a, b) {
      final diffA = a.name.length - ev.phrase.length;
      final diffB = b.name.length - ev.phrase.length;
      final c = diffA.compareTo(diffB);
      if (c != 0) {
        return c;
      } else {
        return a.name.compareTo(b.name);
      }
    });
    yield AlbumSearchBlocSuccess(matches);
    _lastSearch = ev;
  }

  Stream<AlbumSearchBlocState> _onEventUpdateItems(
      AlbumSearchBlocUpdateItemsEvent ev) async* {
    _albums = ev.albums;
    if (_lastSearch != null) {
      // search again
      yield* _onEventSearch(_lastSearch!);
    }
  }

  var _albums = <Album>[];
  AlbumSearchBlocSearchEvent? _lastSearch;

  static final _log = Logger("bloc.album_search.AlbumSearchBloc");
}
