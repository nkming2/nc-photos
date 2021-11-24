import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/list_album.dart';

class ListAlbumBlocItem {
  ListAlbumBlocItem(this.album);

  final Album album;
}

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
  const ListAlbumBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final List<ListAlbumBlocItem> items;
}

class ListAlbumBlocInit extends ListAlbumBlocState {
  const ListAlbumBlocInit() : super(null, const []);
}

class ListAlbumBlocLoading extends ListAlbumBlocState {
  const ListAlbumBlocLoading(Account? account, List<ListAlbumBlocItem> items)
      : super(account, items);
}

class ListAlbumBlocSuccess extends ListAlbumBlocState {
  const ListAlbumBlocSuccess(Account? account, List<ListAlbumBlocItem> items)
      : super(account, items);
}

class ListAlbumBlocFailure extends ListAlbumBlocState {
  const ListAlbumBlocFailure(
      Account? account, List<ListAlbumBlocItem> items, this.exception)
      : super(account, items);

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
  const ListAlbumBlocInconsistent(
      Account? account, List<ListAlbumBlocItem> items)
      : super(account, items);
}

class ListAlbumBloc extends Bloc<ListAlbumBlocEvent, ListAlbumBlocState> {
  ListAlbumBloc() : super(const ListAlbumBlocInit()) {
    _albumUpdatedListener =
        AppEventListener<AlbumUpdatedEvent>(_onAlbumUpdatedEvent);
    _fileRemovedListener =
        AppEventListener<FileRemovedEvent>(_onFileRemovedEvent);
    _albumCreatedListener =
        AppEventListener<AlbumCreatedEvent>(_onAlbumCreatedEvent);
    _albumUpdatedListener.begin();
    _fileRemovedListener.begin();
    _albumCreatedListener.begin();
    _fileMovedListener.begin();
    _shareCreatedListener.begin();
    _shareRemovedListener.begin();

    _refreshThrottler = Throttler(
      onTriggered: (_) {
        add(const _ListAlbumBlocExternalEvent());
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
    _fileMovedListener.end();
    _shareCreatedListener.end();
    _shareRemovedListener.end();
    _refreshThrottler.clear();
    return super.close();
  }

  Stream<ListAlbumBlocState> _onEventQuery(ListAlbumBlocQuery ev) async* {
    yield ListAlbumBlocLoading(ev.account, state.items);
    bool hasContent = state.items.isNotEmpty;

    if (!hasContent) {
      // show something instantly on first load
      final cacheState = await _queryOffline(ev);
      yield ListAlbumBlocLoading(ev.account, cacheState.items);
      hasContent = cacheState.items.isNotEmpty;
    }

    final newState = await _queryOnline(ev);
    if (newState is ListAlbumBlocFailure) {
      yield ListAlbumBlocFailure(
          ev.account,
          newState.items.isNotEmpty ? newState.items : state.items,
          newState.exception);
    } else {
      yield newState;
    }
  }

  Stream<ListAlbumBlocState> _onExternalEvent(
      _ListAlbumBlocExternalEvent ev) async* {
    yield ListAlbumBlocInconsistent(state.account, state.items);
  }

  void _onAlbumUpdatedEvent(AlbumUpdatedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (_isAccountOfInterest(ev.account)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  void _onFileRemovedEvent(FileRemovedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (_isAccountOfInterest(ev.account) &&
        file_util.isAlbumFile(ev.account, ev.file)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
      );
    }
  }

  void _onFileMovedEvent(FileMovedEvent ev) {
    if (state is ListAlbumBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (_isAccountOfInterest(ev.account) &&
        ev.destination
            .startsWith(remote_storage_util.getRemoteAlbumsDir(ev.account))) {
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
    if (_isAccountOfInterest(ev.account)) {
      add(const _ListAlbumBlocExternalEvent());
    }
  }

  void _onShareCreatedEvent(ShareCreatedEvent ev) =>
      _onShareChanged(ev.account, ev.share);

  void _onShareRemovedEvent(ShareRemovedEvent ev) =>
      _onShareChanged(ev.account, ev.share);

  void _onShareChanged(Account account, Share share) {
    if (_isAccountOfInterest(account)) {
      final webdavPath = file_util.unstripPath(account, share.path);
      if (webdavPath
          .startsWith(remote_storage_util.getRemoteAlbumsDir(account))) {
        _refreshThrottler.trigger(
          maxResponceTime: const Duration(seconds: 3),
          maxPendingCount: 10,
        );
      }
    }
  }

  Future<ListAlbumBlocState> _queryOffline(ListAlbumBlocQuery ev) =>
      _queryWithAlbumDataSource(
          ev, FileAppDbDataSource(AppDb()), AlbumAppDbDataSource(AppDb()));

  Future<ListAlbumBlocState> _queryOnline(ListAlbumBlocQuery ev) =>
      _queryWithAlbumDataSource(
          ev, FileCachedDataSource(AppDb()), AlbumCachedDataSource(AppDb()));

  Future<ListAlbumBlocState> _queryWithAlbumDataSource(ListAlbumBlocQuery ev,
      FileDataSource fileDataSource, AlbumDataSource albumDataSrc) async {
    try {
      final albums = <Album>[];
      final errors = <dynamic>[];
      await for (final result in ListAlbum(
          FileRepo(fileDataSource), AlbumRepo(albumDataSrc))(ev.account)) {
        if (result is ExceptionEvent) {
          if (result.error is CacheNotFoundException) {
            _log.info(
                "[_queryWithAlbumDataSource] Cache not found", result.error);
          } else {
            _log.shout("[_queryWithAlbumDataSource] Exception while ListAlbum",
                result.error, result.stackTrace);
          }
          errors.add(result.error);
        } else if (result is Album) {
          albums.add(result);
        }
      }

      final items = albums.map((e) => ListAlbumBlocItem(e)).toList();
      if (errors.isEmpty) {
        return ListAlbumBlocSuccess(ev.account, items);
      } else {
        return ListAlbumBlocFailure(ev.account, items, errors.first);
      }
    } catch (e, stacktrace) {
      _log.severe("[_queryWithAlbumDataSource] Exception", e, stacktrace);
      return ListAlbumBlocFailure(ev.account, [], e);
    }
  }

  bool _isAccountOfInterest(Account account) =>
      state.account == null || state.account!.compareServerIdentity(account);

  late AppEventListener<AlbumUpdatedEvent> _albumUpdatedListener;
  late AppEventListener<FileRemovedEvent> _fileRemovedListener;
  late AppEventListener<AlbumCreatedEvent> _albumCreatedListener;
  late final _fileMovedListener =
      AppEventListener<FileMovedEvent>(_onFileMovedEvent);
  late final _shareCreatedListener =
      AppEventListener<ShareCreatedEvent>(_onShareCreatedEvent);
  late final _shareRemovedListener =
      AppEventListener<ShareRemovedEvent>(_onShareRemovedEvent);

  late Throttler _refreshThrottler;

  static final _log = Logger("bloc.list_album.ListAlbumBloc");
}
