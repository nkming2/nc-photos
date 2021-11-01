import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/use_case/list_pending_shared_album.dart';

class ListPendingSharedAlbumBlocItem {
  ListPendingSharedAlbumBlocItem(this.album);

  final Album album;
}

abstract class ListPendingSharedAlbumBlocEvent {
  const ListPendingSharedAlbumBlocEvent();
}

class ListPendingSharedAlbumBlocQuery extends ListPendingSharedAlbumBlocEvent {
  const ListPendingSharedAlbumBlocQuery(
    this.account,
  );

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

/// An external event has happened and may affect the state of this bloc
class _ListPendingSharedAlbumBlocExternalEvent
    extends ListPendingSharedAlbumBlocEvent {
  const _ListPendingSharedAlbumBlocExternalEvent();

  @override
  toString() {
    return "$runtimeType {"
        "}";
  }
}

abstract class ListPendingSharedAlbumBlocState {
  const ListPendingSharedAlbumBlocState(this.items);

  @override
  toString() {
    return "$runtimeType {"
        "items: List {length: ${items.length}}, "
        "}";
  }

  final List<ListPendingSharedAlbumBlocItem> items;
}

class ListPendingSharedAlbumBlocInit extends ListPendingSharedAlbumBlocState {
  ListPendingSharedAlbumBlocInit() : super(const []);
}

class ListPendingSharedAlbumBlocLoading
    extends ListPendingSharedAlbumBlocState {
  const ListPendingSharedAlbumBlocLoading(
      List<ListPendingSharedAlbumBlocItem> items)
      : super(items);
}

class ListPendingSharedAlbumBlocSuccess
    extends ListPendingSharedAlbumBlocState {
  const ListPendingSharedAlbumBlocSuccess(
      List<ListPendingSharedAlbumBlocItem> items)
      : super(items);
}

class ListPendingSharedAlbumBlocFailure
    extends ListPendingSharedAlbumBlocState {
  const ListPendingSharedAlbumBlocFailure(
      List<ListPendingSharedAlbumBlocItem> items, this.exception)
      : super(items);

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
class ListPendingSharedAlbumBlocInconsistent
    extends ListPendingSharedAlbumBlocState {
  const ListPendingSharedAlbumBlocInconsistent(
      List<ListPendingSharedAlbumBlocItem> items)
      : super(items);
}

/// Return a list of importable shared albums in the pending dir
class ListPendingSharedAlbumBloc extends Bloc<ListPendingSharedAlbumBlocEvent,
    ListPendingSharedAlbumBlocState> {
  ListPendingSharedAlbumBloc() : super(ListPendingSharedAlbumBlocInit()) {
    _fileMovedEventListener.begin();
  }

  @override
  mapEventToState(ListPendingSharedAlbumBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListPendingSharedAlbumBlocQuery) {
      yield* _onEventQuery(event);
    } else if (event is _ListPendingSharedAlbumBlocExternalEvent) {
      yield* _onExternalEvent(event);
    }
  }

  @override
  close() {
    _fileMovedEventListener.end();
    return super.close();
  }

  Stream<ListPendingSharedAlbumBlocState> _onEventQuery(
      ListPendingSharedAlbumBlocQuery ev) async* {
    yield const ListPendingSharedAlbumBlocLoading([]);
    try {
      final fileRepo = FileRepo(FileCachedDataSource(AppDb()));
      final albumRepo = AlbumRepo(AlbumCachedDataSource(AppDb()));
      final albums = <Album>[];
      final errors = <dynamic>[];
      await for (final result
          in ListPendingSharedAlbum(fileRepo, albumRepo)(ev.account)) {
        if (result is ExceptionEvent) {
          _log.severe("[_onEventQuery] Exception while ListPendingSharedAlbum",
              result.error, result.stackTrace);
          errors.add(result.error);
        } else if (result is Album) {
          albums.add(result);
        }
      }
      final items =
          albums.map((e) => ListPendingSharedAlbumBlocItem(e)).toList();
      if (errors.isEmpty) {
        yield ListPendingSharedAlbumBlocSuccess(items);
      } else {
        yield ListPendingSharedAlbumBlocFailure(items, errors.first);
      }
    } catch (e) {
      _log.severe("[_onEventQuery] Exception", e);
      yield ListPendingSharedAlbumBlocFailure(state.items, e);
    }
  }

  Stream<ListPendingSharedAlbumBlocState> _onExternalEvent(
      _ListPendingSharedAlbumBlocExternalEvent ev) async* {
    yield ListPendingSharedAlbumBlocInconsistent(state.items);
  }

  void _onFileMovedEvent(FileMovedEvent ev) {
    if (state is ListPendingSharedAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (ev.file.path.startsWith(
        remote_storage_util.getRemotePendingSharedAlbumsDir(ev.account))) {
      add(const _ListPendingSharedAlbumBlocExternalEvent());
    }
  }

  late final _fileMovedEventListener =
      AppEventListener<FileMovedEvent>(_onFileMovedEvent);

  static final _log =
      Logger("bloc.list_pending_shared_album.ListPendingSharedAlbumBloc");
}
