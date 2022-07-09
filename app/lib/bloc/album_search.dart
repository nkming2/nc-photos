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
  AlbumSearchBloc() : super(const AlbumSearchBlocInit()) {
    on<AlbumSearchBlocEvent>(_onEvent);
  }

  Future<void> _onEvent(
      AlbumSearchBlocEvent event, Emitter<AlbumSearchBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is AlbumSearchBlocSearchEvent) {
      await _onEventSearch(event, emit);
    } else if (event is AlbumSearchBlocUpdateItemsEvent) {
      await _onEventUpdateItems(event, emit);
    }
  }

  Future<void> _onEventSearch(
      AlbumSearchBlocSearchEvent ev, Emitter<AlbumSearchBlocState> emit) async {
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
    emit(AlbumSearchBlocSuccess(matches));
    _lastSearch = ev;
  }

  Future<void> _onEventUpdateItems(AlbumSearchBlocUpdateItemsEvent ev,
      Emitter<AlbumSearchBlocState> emit) async {
    _albums = ev.albums;
    if (_lastSearch != null) {
      // search again
      await _onEventSearch(_lastSearch!, emit);
    }
  }

  var _albums = <Album>[];
  AlbumSearchBlocSearchEvent? _lastSearch;

  static final _log = Logger("bloc.album_search.AlbumSearchBloc");
}
