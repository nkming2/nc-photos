import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/use_case/list_album.dart';

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

  final Account account;
  final List<Album> albums;
}

class ListAlbumBlocInit extends ListAlbumBlocState {
  const ListAlbumBlocInit() : super(null, const []);
}

class ListAlbumBlocLoading extends ListAlbumBlocState {
  const ListAlbumBlocLoading(Account account, List<Album> albums)
      : super(account, albums);
}

class ListAlbumBlocSuccess extends ListAlbumBlocState {
  const ListAlbumBlocSuccess(Account account, List<Album> albums)
      : super(account, albums);
}

class ListAlbumBlocFailure extends ListAlbumBlocState {
  const ListAlbumBlocFailure(
      Account account, List<Album> albums, this.exception)
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
  const ListAlbumBlocInconsistent(Account account, List<Album> albums)
      : super(account, albums);
}

class ListAlbumBloc extends Bloc<ListAlbumBlocEvent, ListAlbumBlocState> {
  ListAlbumBloc() : super(ListAlbumBlocInit()) {
    _fileMetadataUpdatedListener =
        AppEventListener<FileMetadataUpdatedEvent>(_onFileMetadataUpdatedEvent);
    _albumUpdatedListener =
        AppEventListener<AlbumUpdatedEvent>(_onAlbumUpdatedEvent);
    _fileRemovedListener =
        AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
    _albumCreatedListener =
        AppEventListener<AlbumCreatedEvent>(_onAlbumCreatedEvent);
    _fileMetadataUpdatedListener.begin();
    _albumUpdatedListener.begin();
    _fileRemovedListener.begin();
    _albumCreatedListener.begin();
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
    _fileMetadataUpdatedListener.end();
    _albumUpdatedListener.end();
    _fileRemovedListener.end();
    _albumCreatedListener.end();
    return super.close();
  }

  Stream<ListAlbumBlocState> _onEventQuery(ListAlbumBlocQuery ev) async* {
    yield ListAlbumBlocLoading(ev.account, state.albums);
    bool hasContent = state.albums.isNotEmpty;

    if (!hasContent) {
      // show something instantly on first load
      ListAlbumBlocState cacheState = ListAlbumBlocInit();
      await for (final s in _queryOffline(ev, () => cacheState)) {
        cacheState = s;
      }
      yield ListAlbumBlocLoading(ev.account, cacheState.albums);
      hasContent = cacheState.albums.isNotEmpty;
    }

    ListAlbumBlocState newState = ListAlbumBlocInit();
    if (!hasContent) {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
        yield s;
      }
    } else {
      await for (final s in _queryOnline(ev, () => newState)) {
        newState = s;
      }
      if (newState is ListAlbumBlocSuccess) {
        yield newState;
      } else if (newState is ListAlbumBlocFailure) {
        yield ListAlbumBlocFailure(
            ev.account, state.albums, newState.exception);
      }
    }
  }

  Stream<ListAlbumBlocState> _onExternalEvent(
      _ListAlbumBlocExternalEvent ev) async* {
    yield ListAlbumBlocInconsistent(state.account, state.albums);
  }

  void _onFileMetadataUpdatedEvent(FileMetadataUpdatedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    add(_ListAlbumBlocExternalEvent());
  }

  void _onAlbumUpdatedEvent(AlbumUpdatedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    add(_ListAlbumBlocExternalEvent());
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (isAlbumFile(ev.file)) {
      add(_ListAlbumBlocExternalEvent());
    }
  }

  void _onAlbumCreatedEvent(AlbumCreatedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    add(_ListAlbumBlocExternalEvent());
  }

  Stream<ListAlbumBlocState> _queryOffline(
          ListAlbumBlocQuery ev, ListAlbumBlocState Function() getState) =>
      _queryWithAlbumDataSource(
          ev, getState, FileAppDbDataSource(), AlbumAppDbDataSource());

  Stream<ListAlbumBlocState> _queryOnline(
          ListAlbumBlocQuery ev, ListAlbumBlocState Function() getState) =>
      _queryWithAlbumDataSource(
          ev, getState, FileCachedDataSource(), AlbumCachedDataSource());

  Stream<ListAlbumBlocState> _queryWithAlbumDataSource(
      ListAlbumBlocQuery ev,
      ListAlbumBlocState Function() getState,
      FileDataSource fileDataSource,
      AlbumDataSource albumDataSrc) async* {
    try {
      final results = await ListAlbum(
          FileRepo(fileDataSource), AlbumRepo(albumDataSrc))(ev.account);
      yield ListAlbumBlocSuccess(ev.account, results);
    } catch (e, stacktrace) {
      _log.severe(
          "[_queryWithAlbumDataSource] Exception while request", e, stacktrace);
      yield ListAlbumBlocFailure(ev.account, getState().albums, e);
    }
  }

  AppEventListener<FileMetadataUpdatedEvent> _fileMetadataUpdatedListener;
  AppEventListener<AlbumUpdatedEvent> _albumUpdatedListener;
  AppEventListener<FileRemovedEvent> _fileRemovedListener;
  AppEventListener<AlbumCreatedEvent> _albumCreatedListener;

  static final _log = Logger("bloc.list_album.ListAlbumBloc");
}
