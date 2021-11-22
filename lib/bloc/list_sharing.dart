import 'package:bloc/bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/find_file.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:path/path.dart' as path;

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
        items ?? this.items,
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
        items ?? this.items,
        exception ?? this.exception,
      );

  final dynamic exception;
}

/// List shares to be shown in [SharingBrowser]
class ListSharingBloc extends Bloc<ListSharingBlocEvent, ListSharingBlocState> {
  ListSharingBloc() : super(ListSharingBlocInit()) {
    _shareRemovedListener.begin();

    _refreshThrottler = Throttler<Share>(
      onTriggered: (shares) {
        add(_ListSharingBlocShareRemoved(shares));
      },
      logTag: "ListSharingBloc.refresh",
    );
  }

  static ListSharingBloc of(Account account) {
    final id =
        "${account.scheme}://${account.username}@${account.address}?${account.roots.join('&')}";
    try {
      _log.fine("[of] Resolving bloc for '$id'");
      return KiwiContainer().resolve<ListSharingBloc>("ListSharingBloc($id)");
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[of] New bloc instance for account: $account");
      final bloc = ListSharingBloc();
      KiwiContainer().registerInstance<ListSharingBloc>(bloc,
          name: "ListSharingBloc($id)");
      return bloc;
    }
  }

  @override
  close() {
    _shareRemovedListener.end();
    _refreshThrottler.clear();
    return super.close();
  }

  @override
  mapEventToState(ListSharingBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListSharingBlocQuery) {
      yield* _onEventQuery(event);
    } else if (event is _ListSharingBlocShareRemoved) {
      yield* _onEventShareRemoved(event);
    }
  }

  Stream<ListSharingBlocState> _onEventQuery(ListSharingBlocQuery ev) async* {
    try {
      yield ListSharingBlocLoading(ev.account, state.items);
      yield ListSharingBlocSuccess(ev.account, await _query(ev));
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      yield ListSharingBlocFailure(ev.account, state.items, e);
    }
  }

  Stream<ListSharingBlocState> _onEventShareRemoved(
      _ListSharingBlocShareRemoved ev) async* {
    if (state is! ListSharingBlocSuccess && state is! ListSharingBlocFailure) {
      return;
    }
    final newItems = state.items
        .where((element) => !ev.shares.containsIdentical(element.share))
        .toList();
    // i love hacks :)
    yield (state as dynamic).copyWith(
      items: newItems,
    ) as ListSharingBlocState;
  }

  void _onShareRemovedEvent(ShareRemovedEvent ev) {
    _refreshThrottler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
      data: ev.share,
    );
  }

  Future<List<ListSharingItem>> _query(ListSharingBlocQuery ev) async {
    final fileRepo = FileRepo(FileCachedDataSource(AppDb()));
    final sharedAlbumFiles = await Ls(fileRepo)(
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
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    final shares = await shareRepo.listAll(ev.account);
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
      if (path.dirname(webdavPath) ==
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
          .every((r) => r.isNotEmpty && !s.path.startsWith("/$r/"))) {
        // ignore files not under root dirs
        return null;
      }

      try {
        final file = await FindFile(AppDb())(ev.account, s.itemSource);
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
    final fileRepo = FileRepo(FileCachedDataSource(AppDb()));
    final pendingSharedAlbumFiles = await Ls(fileRepo)(
        ev.account,
        File(
          path: remote_storage_util.getRemotePendingSharedAlbumsDir(ev.account),
        ));

    final shareRepo = ShareRepo(ShareRemoteDataSource());
    final shares = await shareRepo.reverseListAll(ev.account);
    final futures = shares.map((s) async {
      final webdavPath = file_util.unstripPath(ev.account, s.path);
      // include pending shared albums
      if (path.dirname(webdavPath) ==
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
      if (path.dirname(webdavPath) ==
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
      final albumRepo = AlbumRepo(AlbumCachedDataSource(AppDb()));
      final album = await albumRepo.get(ev.account, albumFile);
      return ListSharingAlbum(share, album);
    } catch (e, stackTrace) {
      _log.shout(
          "[_querySharedAlbum] Failed while getting album", e, stackTrace);
      return null;
    }
  }

  late final _shareRemovedListener =
      AppEventListener<ShareRemovedEvent>(_onShareRemovedEvent);

  late Throttler _refreshThrottler;

  static final _log = Logger("bloc.list_sharing.ListSharingBloc");
}
