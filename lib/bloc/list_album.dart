import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:tuple/tuple.dart';

abstract class ListAlbumBlocEvent {
  const ListAlbumBlocEvent();
}

class ListAlbumBlocQuery extends ListAlbumBlocEvent {
  const ListAlbumBlocQuery(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

/// An external event has happened and may affect the state of this bloc
class _ListAlbumBlocExternalEvent extends ListAlbumBlocEvent {
  const _ListAlbumBlocExternalEvent();

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }
}

abstract class ListAlbumBlocState {
  const ListAlbumBlocState(this.account, this.albums);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "albums: List {length: ${albums.length}}, "
        "}";
  }

  final Account? account;
  final List<Album> albums;
}

class ListAlbumBlocInit extends ListAlbumBlocState {
  const ListAlbumBlocInit() : super(null, const []);
}

class ListAlbumBlocLoading extends ListAlbumBlocState {
  const ListAlbumBlocLoading(Account? account, List<Album> albums)
      : super(account, albums);
}

class ListAlbumBlocSuccess extends ListAlbumBlocState {
  const ListAlbumBlocSuccess(Account? account, List<Album> albums)
      : super(account, albums);
}

class ListAlbumBlocFailure extends ListAlbumBlocState {
  const ListAlbumBlocFailure(
      Account? account, List<Album> albums, this.exception)
      : super(account, albums);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

/// The state of this bloc is inconsistent. This typically means that the data
/// may have been changed externally
class ListAlbumBlocInconsistent extends ListAlbumBlocState {
  const ListAlbumBlocInconsistent(Account? account, List<Album> albums)
      : super(account, albums);
}

class ListAlbumBloc extends Bloc<ListAlbumBlocEvent, ListAlbumBlocState> {
  ListAlbumBloc() : super(ListAlbumBlocInit()) {
    _albumUpdatedListener =
        AppEventListener<AlbumUpdatedEvent>(_onAlbumUpdatedEvent);
    _fileRemovedListener =
        AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
    _albumCreatedListener =
        AppEventListener<AlbumCreatedEvent>(_onAlbumCreatedEvent);
    _albumUpdatedListener.begin();
    _fileRemovedListener.begin();
    _albumCreatedListener.begin();

    _refreshThrottler = Throttler(
      onTriggered: (_) {
        add(_ListAlbumBlocExternalEvent());
      },
      logTag: "ListAlbumBloc.refresh",
    );
  }

  @override
  mapEventToState(ListAlbumBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListAlbumBlocQuery) {
      yield* _onEventQuery(event);
    } else if (event is _ListAlbumBlocExternalEvent) {
      yield* _onExternalEvent(event);
    }
  }

  @override
  close() {
    _albumUpdatedListener.end();
    _fileRemovedListener.end();
    _albumCreatedListener.end();
    _refreshThrottler.clear();
    return super.close();
  }

  Stream<ListAlbumBlocState> _onEventQuery(ListAlbumBlocQuery ev) async* {
    yield ListAlbumBlocLoading(ev.account, state.albums);
    bool hasContent = state.albums.isNotEmpty;

    if (!hasContent) {
      // show something instantly on first load
      final cacheState = await _queryOffline(ev);
      yield ListAlbumBlocLoading(ev.account, cacheState.albums);
      hasContent = cacheState.albums.isNotEmpty;
    }

    final newState = await _queryOnline(ev);
    if (newState is ListAlbumBlocFailure) {
      yield ListAlbumBlocFailure(
          ev.account,
          newState.albums.isNotEmpty ? newState.albums : state.albums,
          newState.exception);
    } else {
      yield newState;
    }
  }

  Stream<ListAlbumBlocState> _onExternalEvent(
      _ListAlbumBlocExternalEvent ev) async* {
    yield ListAlbumBlocInconsistent(state.account, state.albums);
  }

  void _onAlbumUpdatedEvent(AlbumUpdatedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
    );
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (isAlbumFile(ev.account, ev.file)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  void _onAlbumCreatedEvent(AlbumCreatedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    add(_ListAlbumBlocExternalEvent());
  }

  Future<ListAlbumBlocState> _queryOffline(ListAlbumBlocQuery ev) =>
      _queryWithAlbumDataSource(
          ev, FileAppDbDataSource(), AlbumAppDbDataSource());

  Future<ListAlbumBlocState> _queryOnline(ListAlbumBlocQuery ev) =>
      _queryWithAlbumDataSource(
          ev, FileCachedDataSource(), AlbumCachedDataSource());

  Future<ListAlbumBlocState> _queryWithAlbumDataSource(ListAlbumBlocQuery ev,
      FileDataSource fileDataSource, AlbumDataSource albumDataSrc) async {
    try {
      final albums = <Album>[];
      final errors = <dynamic>[];
      await for (final result in ListAlbum(
          FileRepo(fileDataSource), AlbumRepo(albumDataSrc))(ev.account)) {
        if (result is Tuple2) {
          if (result.item1 is CacheNotFoundException) {
            _log.info(
                "[_queryWithAlbumDataSource] Cache not found", result.item1);
          } else {
            _log.shout("[_queryWithAlbumDataSource] Exception while ListAlbum",
                result.item1, result.item2);
          }
          errors.add(result.item1);
        } else if (result is Album) {
          albums.add(result);
        }
      }
      if (errors.isEmpty) {
        return ListAlbumBlocSuccess(ev.account, albums);
      } else {
        return ListAlbumBlocFailure(ev.account, albums, errors.first);
      }
    } catch (e, stacktrace) {
      _log.severe("[_queryWithAlbumDataSource] Exception", e, stacktrace);
      return ListAlbumBlocFailure(ev.account, [], e);
    }
  }

  late AppEventListener<AlbumUpdatedEvent> _albumUpdatedListener;
  late AppEventListener<FileRemovedEvent> _fileRemovedListener;
  late AppEventListener<AlbumCreatedEvent> _albumCreatedListener;

  late Throttler _refreshThrottler;

  static final _log = Logger("bloc.list_album.ListAlbumBloc");
}
