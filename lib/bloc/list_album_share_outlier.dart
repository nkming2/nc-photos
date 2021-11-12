import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/list_sharee.dart';

class ListAlbumShareOutlierItem with EquatableMixin {
  const ListAlbumShareOutlierItem(this.file, this.shareItems);

  @override
  toString() {
    return "$runtimeType {"
        "file: '${file.path}', "
        "shareItems: ${shareItems.toReadableString()}, "
        "}";
  }

  @override
  get props => [
        file,
        shareItems,
      ];

  final File file;
  final List<ListAlbumShareOutlierShareItem> shareItems;
}

abstract class ListAlbumShareOutlierShareItem with EquatableMixin {
  const ListAlbumShareOutlierShareItem();
}

class ListAlbumShareOutlierExtraShareItem
    extends ListAlbumShareOutlierShareItem {
  const ListAlbumShareOutlierExtraShareItem(this.share);

  @override
  toString() {
    return "$runtimeType {"
        "share: $share, "
        "}";
  }

  @override
  get props => [
        share,
      ];

  final Share share;
}

class ListAlbumShareOutlierMissingShareItem
    extends ListAlbumShareOutlierShareItem {
  const ListAlbumShareOutlierMissingShareItem(
      this.shareWith, this.shareWithDisplayName);

  @override
  toString() {
    return "$runtimeType {"
        "shareWith: $shareWith, "
        "shareWithDisplayName: $shareWithDisplayName, "
        "}";
  }

  @override
  get props => [
        shareWith,
        shareWithDisplayName,
      ];

  final CiString shareWith;
  final String? shareWithDisplayName;
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

abstract class ListAlbumShareOutlierBlocState with EquatableMixin {
  const ListAlbumShareOutlierBlocState(this.account, this.items);

  @override
  toString() {
    return "$runtimeType {"
        "account: $account, "
        "items: ${items.toReadableString()}, "
        "}";
  }

  @override
  get props => [
        account,
        items,
      ];

  final Account? account;
  final List<ListAlbumShareOutlierItem> items;
}

class ListAlbumShareOutlierBlocInit extends ListAlbumShareOutlierBlocState {
  ListAlbumShareOutlierBlocInit() : super(null, const []);
}

class ListAlbumShareOutlierBlocLoading extends ListAlbumShareOutlierBlocState {
  const ListAlbumShareOutlierBlocLoading(
      Account? account, List<ListAlbumShareOutlierItem> items)
      : super(account, items);
}

class ListAlbumShareOutlierBlocSuccess extends ListAlbumShareOutlierBlocState {
  const ListAlbumShareOutlierBlocSuccess(
      Account? account, List<ListAlbumShareOutlierItem> items)
      : super(account, items);
}

class ListAlbumShareOutlierBlocFailure extends ListAlbumShareOutlierBlocState {
  const ListAlbumShareOutlierBlocFailure(
      Account? account, List<ListAlbumShareOutlierItem> items, this.exception)
      : super(account, items);

  @override
  toString() {
    return "$runtimeType {"
        "super: ${super.toString()}, "
        "exception: $exception, "
        "}";
  }

  @override
  get props => [
        ...super.props,
        exception,
      ];

  final dynamic exception;
}

/// List the outliers in a shared album
///
/// An outlier is a file where its shares are different to the album's that it
/// belongs, e.g., an unshared item in a shared album, or vice versa
class ListAlbumShareOutlierBloc extends Bloc<ListAlbumShareOutlierBlocEvent,
    ListAlbumShareOutlierBlocState> {
  ListAlbumShareOutlierBloc(this.shareRepo, this.shareeRepo)
      : super(ListAlbumShareOutlierBlocInit());

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
      yield ListAlbumShareOutlierBlocLoading(ev.account, state.items);

      final albumShares = await () async {
        var temp = (ev.album.shares ?? [])
            .where((s) => s.userId != ev.account.username)
            .toList();
        if (ev.album.albumFile!.ownerId != ev.account.username) {
          // add owner if the album is not owned by this account
          final ownerSharee = (await ListSharee(shareeRepo)(ev.account))
              .firstWhere((s) => s.shareWith == ev.album.albumFile!.ownerId);
          temp.add(AlbumShare(
            userId: ownerSharee.shareWith,
            displayName: ownerSharee.shareWithDisplayNameUnique,
          ));
        }
        return Map.fromEntries(temp.map((as) => MapEntry(as.userId, as)));
      }();
      final albumSharees = albumShares.values.map((s) => s.userId).toSet();

      final products = <ListAlbumShareOutlierItem>[];
      final errors = <Object>[];
      products.addAll(await _processAlbumFile(
          ev.account, ev.album, albumShares, albumSharees, errors));
      products.addAll(await _processAlbumItems(
          ev.account, ev.album, albumShares, albumSharees, errors));

      if (errors.isEmpty) {
        yield ListAlbumShareOutlierBlocSuccess(ev.account, products);
      } else {
        yield ListAlbumShareOutlierBlocFailure(
            ev.account, products, errors.first);
      }
    } catch (e, stackTrace) {
      _log.severe("[_onEventQuery] Exception while request", e, stackTrace);
      yield ListAlbumShareOutlierBlocFailure(ev.account, state.items, e);
    }
  }

  Future<List<ListAlbumShareOutlierItem>> _processAlbumFile(
    Account account,
    Album album,
    Map<CiString, AlbumShare> albumShares,
    Set<CiString> albumSharees,
    List<Object> errors,
  ) async {
    try {
      final item = await _processSingleFile(
          account, album.albumFile!, albumShares, albumSharees, errors);
      return item == null ? [] : [item];
    } catch (e, stackTrace) {
      _log.severe(
          "[_processAlbumFile] Failed while _processSingleFile: ${logFilename(album.albumFile?.path)}",
          e,
          stackTrace);
      errors.add(e);
      return [];
    }
  }

  Future<List<ListAlbumShareOutlierItem>> _processAlbumItems(
    Account account,
    Album album,
    Map<CiString, AlbumShare> albumShares,
    Set<CiString> albumSharees,
    List<Object> errors,
  ) async {
    final products = <ListAlbumShareOutlierItem>[];
    final files = AlbumStaticProvider.of(album)
        .items
        .whereType<AlbumFileItem>()
        .map((e) => e.file)
        .toList();
    for (final f in files) {
      try {
        (await _processSingleFile(
                account, f, albumShares, albumSharees, errors))
            ?.apply((item) {
          products.add(item);
        });
      } catch (e, stackTrace) {
        _log.severe(
            "[_processAlbumItems] Failed while _processSingleFile: ${logFilename(f.path)}",
            e,
            stackTrace);
        errors.add(e);
      }
    }
    return products;
  }

  Future<ListAlbumShareOutlierItem?> _processSingleFile(
    Account account,
    File file,
    Map<CiString, AlbumShare> albumShares,
    Set<CiString> albumSharees,
    List<Object> errors,
  ) async {
    final shareItems = <ListAlbumShareOutlierShareItem>[];
    final shares = (await ListShare(shareRepo)(account, file))
        .where((element) => element.shareType == ShareType.user)
        .toList();
    final sharees = shares.map((s) => s.shareWith!).toSet();
    final missings = albumSharees.difference(sharees);
    _log.info(
        "Missing shares: ${missings.toReadableString()} for file: ${logFilename(file.path)}");
    for (final m in missings) {
      try {
        final as = albumShares[m]!;
        shareItems.add(
            ListAlbumShareOutlierMissingShareItem(as.userId, as.displayName));
      } catch (e, stackTrace) {
        _log.severe(
            "[_processSingleFile] Failed while processing missing share for file: ${logFilename(file.path)}",
            e,
            stackTrace);
        errors.add(e);
      }
    }
    final extras = sharees.difference(albumSharees);
    _log.info(
        "Extra shares: ${extras.toReadableString()} for file: ${logFilename(file.path)}");
    for (final e in extras) {
      try {
        shareItems.add(ListAlbumShareOutlierExtraShareItem(
            shares.firstWhere((s) => s.shareWith == e)));
      } catch (e, stackTrace) {
        _log.severe(
            "[_processSingleFile] Failed while processing extra share for file: ${logFilename(file.path)}",
            e,
            stackTrace);
        errors.add(e);
      }
    }
    if (shareItems.isNotEmpty) {
      return ListAlbumShareOutlierItem(file, shareItems);
    } else {
      return null;
    }
  }

  final ShareRepo shareRepo;
  final ShareeRepo shareeRepo;

  static final _log =
      Logger("bloc.list_album_share_outlier.ListAlbumShareOutlierBloc");
}
