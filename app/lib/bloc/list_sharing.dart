import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/bloc_util.dart' as bloc_util;
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/find_file.dart';
import 'package:nc_photos/use_case/list_share_with_me.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:path/path.dart' as path_lib;

abstract class ListSharingItem {
  const ListSharingItem(this.share);

  final Share share;
}

class ListSharingFile extends ListSharingItem {
  const ListSharingFile(Share share, this.file) : super(share);

  final File file;
}

class ListSharingAlbum extends ListSharingItem {
  const ListSharingAlbum(Share share, this.album) : super(share);

  final Album album;
}

abstract class ListSharingBlocEvent {
  const ListSharingBlocEvent();
}

class ListSharingBlocQuery extends ListSharingBlocEvent {
  const ListSharingBlocQuery(this.account);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "}";
  }

  final Account account;
}

class _ListSharingBlocShareRemoved extends ListSharingBlocEvent {
  const _ListSharingBlocShareRemoved(this.shares);

  @override
  toString() {
    return "$runtimeType {"
        "shares: ${shares.toReadableString()}, "
        "}";
  }

  final List<Share> shares;
}

class _ListSharingBlocPendingSharedAlbumMoved extends ListSharingBlocEvent {
  const _ListSharingBlocPendingSharedAlbumMoved(
      this.account, this.file, this.destination);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "file: $file, "
        "destination: $destination, "
        "}";
  }

  final Account account;
  final File file;
  final String destination;
}

abstract class ListSharingBlocState {
  const ListSharingBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final List<ListSharingItem> items;
}

class ListSharingBlocInit extends ListSharingBlocState {
  ListSharingBlocInit() : super(null, const []);
}

class ListSharingBlocLoading extends ListSharingBlocState {
  const ListSharingBlocLoading(Account? account, List<ListSharingItem> items)
      : super(account, items);
}

class ListSharingBlocSuccess extends ListSharingBlocState {
  const ListSharingBlocSuccess(Account? account, List<ListSharingItem> items)
      : super(account, items);

  ListSharingBlocSuccess copyWith({
    Account? account,
    List<ListSharingItem>? items,
  }) =>
      ListSharingBlocSuccess(
        account ?? this.account,
        items ?? List.of(this.items),
      );
}

class ListSharingBlocFailure extends ListSharingBlocState {
  const ListSharingBlocFailure(
      Account? account, List<ListSharingItem> items, this.exception)
      : super(account, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  ListSharingBlocFailure copyWith({
    Account? account,
    List<ListSharingItem>? items,
    dynamic exception,
  }) =>
      ListSharingBlocFailure(
        account ?? this.account,
        items ?? List.of(this.items),
        exception ?? this.exception,
      );

  final dynamic exception;
}

/// List shares to be shown in [SharingBrowser]
class ListSharingBloc extends Bloc<ListSharingBlocEvent, ListSharingBlocState> {
  ListSharingBloc(this._c)
      : assert(require(_c)),
        assert(FindFile.require(_c)),
        assert(ListShareWithMe.require(_c)),
        assert(LsSingleFile.require(_c)),
        super(ListSharingBlocInit()) {
    _shareRemovedListener.begin();
    _fileMovedEventListener.begin();

    _refreshThrottler = Throttler<Share>(
      onTriggered: (shares) {
        add(_ListSharingBlocShareRemoved(shares));
      },
      logTag: "ListSharingBloc.refresh",
    );

    on<ListSharingBlocEvent>(_onEvent);
  }

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.albumRepo) &&
      DiContainer.has(c, DiType.fileRepo) &&
      DiContainer.has(c, DiType.shareRepo);

  static ListSharingBloc of(Account account) {
    final name =
        bloc_util.getInstNameForRootAwareAccount("ListSharingBloc", account);
    try {
      _log.fine("[of] Resolving bloc for '$name'");
      return KiwiContainer().resolve<ListSharingBloc>(name);
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ListSharingBloc(KiwiContainer().resolve<DiContainer>());
      KiwiContainer().registerInstance<ListSharingBloc>(bloc, name: name);
      return bloc;
    }
  }

  @override
  close() {
    _shareRemovedListener.end();
    _fileMovedEventListener.end();
    _refreshThrottler.clear();
    return super.close();
  }

  Future<void> _onEvent(
      ListSharingBlocEvent event, Emitter<ListSharingBlocState> emit) async {
    _log.info("[_onEvent] $event");
    if (event is ListSharingBlocQuery) {
      await _onEventQuery(event, emit);
    } else if (event is _ListSharingBlocShareRemoved) {
      await _onEventShareRemoved(event, emit);
    } else if (event is _ListSharingBlocPendingSharedAlbumMoved) {
      await _onEventPendingSharedAlbumMoved(event, emit);
    }
  }

  Future<void> _onEventQuery(
      ListSharingBlocQuery ev, Emitter<ListSharingBlocState> emit) async {
    try {
      emit(ListSharingBlocLoading(ev.account, state.items));
      emit(ListSharingBlocSuccess(ev.account, await _query(ev)));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      emit(ListSharingBlocFailure(ev.account, state.items, e));
    }
  }

  Future<void> _onEventShareRemoved(_ListSharingBlocShareRemoved ev,
      Emitter<ListSharingBlocState> emit) async {
    if (state is! ListSharingBlocSuccess && state is! ListSharingBlocFailure) {
      return;
    }
    final newItems =
        state.items.where((i) => !ev.shares.contains(i.share)).toList();
    // i love hacks :)
    emit((state as dynamic).copyWith(
      items: newItems,
    ) as ListSharingBlocState);
  }

  Future<void> _onEventPendingSharedAlbumMoved(
      _ListSharingBlocPendingSharedAlbumMoved ev,
      Emitter<ListSharingBlocState> emit) async {
    if (state.items.isEmpty) {
      return;
    }
    try {
      emit(ListSharingBlocLoading(ev.account, state.items));

      final items = List.of(state.items);
      items.removeWhere(
          (i) => i is ListSharingAlbum && i.share.path == ev.file.strippedPath);
      final newShares =
          await ListShareWithMe(_c)(ev.account, File(path: ev.destination));
      final newAlbumFile = await LsSingleFile(_c)(ev.account, ev.destination);
      final newAlbum = await _c.albumRepo.get(ev.account, newAlbumFile);
      for (final s in newShares) {
        items.add(ListSharingAlbum(s, newAlbum));
      }

      emit(ListSharingBlocSuccess(ev.account, items));
    } catch (e, stackTrace) {
      _log.severe("[_onEventPendingSharedAlbumMoved] Exception while request",
          e, stackTrace);
      emit(ListSharingBlocFailure(ev.account, state.items, e));
    }
  }

  void _onShareRemovedEvent(ShareRemovedEvent ev) {
    if (_isAccountOfInterest(ev.account)) {
      _refreshThrottler.trigger(
        maxResponceTime: const Duration(seconds: 3),
        maxPendingCount: 10,
        data: ev.share,
      );
    }
  }

  void _onFileMovedEvent(FileMovedEvent ev) {
    if (state is ListSharingBlocInit) {
      // no data in this bloc, ignore
      return;
    }
    if (_isAccountOfInterest(ev.account)) {
      if (ev.destination
              .startsWith(remote_storage_util.getRemoteAlbumsDir(ev.account)) &&
          ev.file.path.startsWith(remote_storage_util
              .getRemotePendingSharedAlbumsDir(ev.account))) {
        // moving from/to pending dir
        add(_ListSharingBlocPendingSharedAlbumMoved(
            ev.account, ev.file, ev.destination));
      }
    }
  }

  Future<List<ListSharingItem>> _query(ListSharingBlocQuery ev) async {
    final sharedAlbumFiles = await Ls(_c.fileRepo)(
        ev.account,
        File(
          path: remote_storage_util.getRemoteAlbumsDir(ev.account),
        ));
    return (await Future.wait([
      _querySharesByMe(ev, sharedAlbumFiles),
      _querySharesWithMe(ev, sharedAlbumFiles),
    ]))
        .reduce((value, element) => value + element);
  }

  Future<List<ListSharingItem>> _querySharesByMe(
      ListSharingBlocQuery ev, List<File> sharedAlbumFiles) async {
    final shares = await _c.shareRepo.listAll(ev.account);
    final futures = shares.map((s) async {
      final webdavPath = file_util.unstripPath(ev.account, s.path);
      // include link share dirs
      if (s.itemType == ShareItemType.folder) {
        if (webdavPath.startsWith(
            remote_storage_util.getRemoteLinkSharesDir(ev.account))) {
          return ListSharingFile(
            s,
            File(
              path: webdavPath,
              isCollection: true,
            ),
          );
        }
      }
      // include shared albums
      if (path_lib.dirname(webdavPath) ==
          remote_storage_util.getRemoteAlbumsDir(ev.account)) {
        try {
          final file = sharedAlbumFiles
              .firstWhere((element) => element.fileId == s.itemSource);
          return await _querySharedAlbum(ev, s, file);
        } catch (e, stackTrace) {
          _log.severe(
              "[_querySharesWithMe] Shared album not found: ${s.itemSource}",
              e,
              stackTrace);
          return null;
        }
      }

      if (!file_util.isSupportedMime(s.mimeType)) {
        return null;
      }
      // show only link shares
      if (s.url == null) {
        return null;
      }
      if (ev.account.roots
          .every((r) => r.isNotEmpty && !s.path.startsWith("$r/"))) {
        // ignore files not under root dirs
        return null;
      }

      try {
        final file = (await FindFile(_c)(ev.account, [s.itemSource])).first;
        return ListSharingFile(s, file);
      } catch (e, stackTrace) {
        _log.severe("[_querySharesByMe] File not found: ${s.itemSource}", e,
            stackTrace);
        return null;
      }
    });
    return (await Future.wait(futures)).whereType<ListSharingItem>().toList();
  }

  Future<List<ListSharingItem>> _querySharesWithMe(
      ListSharingBlocQuery ev, List<File> sharedAlbumFiles) async {
    final pendingSharedAlbumFiles = await Ls(_c.fileRepo)(
        ev.account,
        File(
          path: remote_storage_util.getRemotePendingSharedAlbumsDir(ev.account),
        ));

    final shares = await _c.shareRepo.reverseListAll(ev.account);
    final futures = shares.map((s) async {
      final webdavPath = file_util.unstripPath(ev.account, s.path);
      // include pending shared albums
      if (path_lib.dirname(webdavPath) ==
          remote_storage_util.getRemotePendingSharedAlbumsDir(ev.account)) {
        try {
          final file = pendingSharedAlbumFiles
              .firstWhere((element) => element.fileId == s.itemSource);
          return await _querySharedAlbum(ev, s, file);
        } catch (e, stackTrace) {
          _log.severe(
              "[_querySharesWithMe] Pending shared album not found: ${s.itemSource}",
              e,
              stackTrace);
          return null;
        }
      }
      // include shared albums
      if (path_lib.dirname(webdavPath) ==
          remote_storage_util.getRemoteAlbumsDir(ev.account)) {
        try {
          final file = sharedAlbumFiles
              .firstWhere((element) => element.fileId == s.itemSource);
          return await _querySharedAlbum(ev, s, file);
        } catch (e, stackTrace) {
          _log.severe(
              "[_querySharesWithMe] Shared album not found: ${s.itemSource}",
              e,
              stackTrace);
          return null;
        }
      }
    });
    return (await Future.wait(futures)).whereType<ListSharingItem>().toList();
  }

  Future<ListSharingItem?> _querySharedAlbum(
      ListSharingBlocQuery ev, Share share, File albumFile) async {
    try {
      final album = await _c.albumRepo.get(ev.account, albumFile);
      return ListSharingAlbum(share, album);
    } catch (e, stackTrace) {
      _log.shout(
          "[_querySharedAlbum] Failed while getting album", e, stackTrace);
      return null;
    }
  }

  bool _isAccountOfInterest(Account account) =>
      state.account == null || state.account!.compareServerIdentity(account);

  final DiContainer _c;

  late final _shareRemovedListener =
      AppEventListener<ShareRemovedEvent>(_onShareRemovedEvent);
  late final _fileMovedEventListener =
      AppEventListener<FileMovedEvent>(_onFileMovedEvent);

  late Throttler _refreshThrottler;

  static final _log = Logger("bloc.list_sharing.ListSharingBloc");
}
