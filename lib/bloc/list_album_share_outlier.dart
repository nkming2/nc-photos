import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/use_case/list_share.dart';

class ListAlbumShareOutlierItem {
  const ListAlbumShareOutlierItem(this.file, this.shares);

  final File file;
  final List<Share> shares;
}

abstract class ListAlbumShareOutlierBlocEvent {
  const ListAlbumShareOutlierBlocEvent();
}

class ListAlbumShareOutlierBlocQuery extends ListAlbumShareOutlierBlocEvent {
  const ListAlbumShareOutlierBlocQuery(this.account, this.album);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "album: $album, "
        "}";
  }

  final Account account;
  final Album album;
}

abstract class ListAlbumShareOutlierBlocState {
  const ListAlbumShareOutlierBlocState(
      this.account, this.albumShares, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "albumShares: List {length: ${albumShares.length}}, "
        "items: List {length: ${items.length}}, "
        "}";
  }

  final Account? account;
  final List<Share> albumShares;
  final List<ListAlbumShareOutlierItem> items;
}

class ListAlbumShareOutlierBlocInit extends ListAlbumShareOutlierBlocState {
  ListAlbumShareOutlierBlocInit() : super(null, const [], const []);
}

class ListAlbumShareOutlierBlocLoading extends ListAlbumShareOutlierBlocState {
  const ListAlbumShareOutlierBlocLoading(Account? account,
      List<Share> albumShares, List<ListAlbumShareOutlierItem> items)
      : super(account, albumShares, items);
}

class ListAlbumShareOutlierBlocSuccess extends ListAlbumShareOutlierBlocState {
  const ListAlbumShareOutlierBlocSuccess(Account? account,
      List<Share> albumShares, List<ListAlbumShareOutlierItem> items)
      : super(account, albumShares, items);
}

class ListAlbumShareOutlierBlocFailure extends ListAlbumShareOutlierBlocState {
  const ListAlbumShareOutlierBlocFailure(
      Account? account,
      List<Share> albumShares,
      List<ListAlbumShareOutlierItem> items,
      this.exception)
      : super(account, albumShares, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  final dynamic exception;
}

/// List the outliers in a shared album
///
/// An outlier is a file where its shares are different to the album's that it
/// belongs, e.g., an unshared item in a shared album, or vice versa
class ListAlbumShareOutlierBloc extends Bloc<ListAlbumShareOutlierBlocEvent,
    ListAlbumShareOutlierBlocState> {
  ListAlbumShareOutlierBloc() : super(ListAlbumShareOutlierBlocInit());

  @override
  mapEventToState(ListAlbumShareOutlierBlocEvent event) async* {
    _log.info("[mapEventToState] $event");
    if (event is ListAlbumShareOutlierBlocQuery) {
      yield* _onEventQuery(event);
    }
  }

  Stream<ListAlbumShareOutlierBlocState> _onEventQuery(
      ListAlbumShareOutlierBlocQuery ev) async* {
    try {
      assert(ev.album.provider is AlbumStaticProvider);
      yield ListAlbumShareOutlierBlocLoading(
          ev.account, state.albumShares, state.items);

      final shareRepo = ShareRepo(ShareRemoteDataSource());
      final albumShares =
          (await ListShare(shareRepo)(ev.account, ev.album.albumFile!))
              .where((element) => element.shareWith != null)
              .sorted((a, b) => a.shareWith!.compareTo(b.shareWith!));
      final albumSharees = albumShares
          .where((element) => element.shareType == ShareType.user)
          .map((e) => e.shareWith!)
          .sorted();
      final files = AlbumStaticProvider.of(ev.album)
          .items
          .whereType<AlbumFileItem>()
          .map((e) => e.file)
          .toList();
      final products = <ListAlbumShareOutlierItem>[];
      Object? error;
      for (final f in files) {
        try {
          final shares = (await ListShare(shareRepo)(ev.account, f))
              .where((element) => element.shareType == ShareType.user)
              .toList();
          final sharees = shares.map((e) => e.shareWith!).sorted();
          if (!listEquals(sharees, albumSharees)) {
            products.add(ListAlbumShareOutlierItem(f, shares));
          }
        } catch (e, stackTrace) {
          _log.severe("[_query] Failed while listing share for file: ${f.path}",
              e, stackTrace);
          error = e;
        }
      }
      if (error == null) {
        yield ListAlbumShareOutlierBlocSuccess(
            ev.account, albumShares, products);
      } else {
        yield ListAlbumShareOutlierBlocFailure(
            ev.account, albumShares, products, error);
      }
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      yield ListAlbumShareOutlierBlocFailure(
          ev.account, state.albumShares, state.items, e);
    }
  }

  static final _log =
      Logger("bloc.list_album_share_outlier.ListAlbumShareOutlierBloc");
}
