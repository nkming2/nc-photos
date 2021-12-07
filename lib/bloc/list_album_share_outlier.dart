import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
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
/// belongs, e.g., an unshared item in a shared album, or vice versa.
///
/// Different users are responsible to manage shares for different files. For
/// the owner of the album, they are responsible to manage:
/// 1. files added by yourself
/// 2. files added by other users: for each participants, any files that are
/// added before the album share for him/her was created
///
/// For other users, they are responsible to manage:
/// 1. shares between you and the owner for all files added by you
/// 2. files added by you: for each participants, any files that are
/// added on or after the album share for him/her was created
class ListAlbumShareOutlierBloc extends Bloc<ListAlbumShareOutlierBlocEvent,
    ListAlbumShareOutlierBlocState> {
  ListAlbumShareOutlierBloc(this._c)
      : assert(require(_c)),
        assert(ListShare.require(_c)),
        super(ListAlbumShareOutlierBlocInit());

  static bool require(DiContainer c) => DiContainer.has(c, DiType.shareeRepo);

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
          final ownerSharee = (await ListSharee(_c.shareeRepo)(ev.account))
              .firstWhere((s) => s.shareWith == ev.album.albumFile!.ownerId);
          temp.add(AlbumShare(
            userId: ownerSharee.shareWith,
            displayName: ownerSharee.label,
          ));
        }
        return Map.fromEntries(temp.map((as) => MapEntry(as.userId, as)));
      }();

      final products = <ListAlbumShareOutlierItem>[];
      final errors = <Object>[];
      products.addAll(
          await _processAlbumFile(ev.account, ev.album, albumShares, errors));
      products.addAll(
          await _processAlbumItems(ev.account, ev.album, albumShares, errors));

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
    List<Object> errors,
  ) async {
    if (!album.albumFile!.isOwned(account.username)) {
      // album file is always managed by the owner
      return [];
    }

    final shareItems = <ListAlbumShareOutlierShareItem>[];
    try {
      final albumSharees = albumShares.values.map((s) => s.userId).toSet();
      final shares = (await ListShare(_c)(account, album.albumFile!))
          .where((element) => element.shareType == ShareType.user)
          .toList();
      final sharees = shares.map((s) => s.shareWith!).toSet();
      final missings = albumSharees.difference(sharees);
      _log.info(
          "[_processAlbumFile] Missing shares: ${missings.toReadableString()}");
      shareItems.addAll(missings.map((e) => albumShares[e]!).map((s) =>
          ListAlbumShareOutlierMissingShareItem(s.userId, s.displayName)));
      final extras = sharees.difference(albumSharees);
      _log.info(
          "[_processAlbumFile] Extra shares: ${extras.toReadableString()}");
      shareItems.addAll(extras
          .map((e) => shares.firstWhere((s) => s.shareWith == e))
          .map((s) => ListAlbumShareOutlierExtraShareItem(s)));
    } catch (e, stackTrace) {
      _log.severe(
          "[_processAlbumFile] Exception: ${logFilename(album.albumFile?.path)}",
          e,
          stackTrace);
      errors.add(e);
      return [];
    }

    if (shareItems.isNotEmpty) {
      return [ListAlbumShareOutlierItem(album.albumFile!, shareItems)];
    } else {
      return [];
    }
  }

  Future<List<ListAlbumShareOutlierItem>> _processAlbumItems(
    Account account,
    Album album,
    Map<CiString, AlbumShare> albumShares,
    List<Object> errors,
  ) async {
    final products = <ListAlbumShareOutlierItem>[];
    final fileItems =
        AlbumStaticProvider.of(album).items.whereType<AlbumFileItem>().toList();
    for (final fi in fileItems) {
      try {
        (await _processSingleFileItem(account, album, fi, albumShares, errors))
            ?.apply((item) {
          products.add(item);
        });
      } catch (e, stackTrace) {
        _log.severe(
            "[_processAlbumItems] Failed while _processSingleFile: ${logFilename(fi.file.path)}",
            e,
            stackTrace);
        errors.add(e);
      }
    }
    return products;
  }

  Future<ListAlbumShareOutlierItem?> _processSingleFileItem(
    Account account,
    Album album,
    AlbumFileItem fileItem,
    Map<CiString, AlbumShare> albumShares,
    List<Object> errors,
  ) async {
    final shareItems = <ListAlbumShareOutlierShareItem>[];
    final shares = (await ListShare(_c)(
      account,
      fileItem.file,
      isIncludeReshare: true,
    ))
        .where((s) => s.shareType == ShareType.user)
        .toList();
    final albumSharees = albumShares.keys.toSet();
    final managedAlbumSharees = albumShares.values
        .where((s) => _isItemSharePairOfInterest(account, album, fileItem, s))
        .map((s) => s.userId)
        .toSet();
    _log.info(
        "[_processSingleFileItem] Sharees: ${albumSharees.map((s) => managedAlbumSharees.contains(s) ? "(managed)$s" : s).toReadableString()} for file: ${logFilename(fileItem.file.path)}");

    // check all shares (including reshares) against sharees that are managed by
    // us
    final allSharees = shares.map((s) => s.shareWith!).toSet();
    var missings = managedAlbumSharees
        .difference(allSharees)
        // Can't share to ourselves or the file owner
        .where((s) => s != account.username && s != fileItem.file.ownerId)
        .toList();
    _log.info(
        "[_processSingleFileItem] Missing shares: ${missings.toReadableString()} for file: ${logFilename(fileItem.file.path)}");
    for (final m in missings) {
      final as = albumShares[m]!;
      shareItems.add(
          ListAlbumShareOutlierMissingShareItem(as.userId, as.displayName));
    }

    // check owned shares against all album sharees. Use all album sharees such
    // that non-managed sharees will not be listed
    final ownedSharees = shares
        .where((s) => s.uidOwner == account.username)
        .map((s) => s.shareWith!)
        .toSet();
    final extras = ownedSharees.difference(albumSharees);
    _log.info(
        "[_processSingleFileItem] Extra shares: ${extras.toReadableString()} for file: ${logFilename(fileItem.file.path)}");
    for (final e in extras) {
      try {
        shareItems.add(ListAlbumShareOutlierExtraShareItem(
            shares.firstWhere((s) => s.shareWith == e)));
      } catch (e, stackTrace) {
        _log.severe(
            "[_processSingleFileItem] Failed while processing extra share for file: ${logFilename(fileItem.file.path)}",
            e,
            stackTrace);
        errors.add(e);
      }
    }
    if (shareItems.isNotEmpty) {
      return ListAlbumShareOutlierItem(fileItem.file, shareItems);
    } else {
      return null;
    }
  }

  bool _isItemSharePairOfInterest(
      Account account, Album album, AlbumItem item, AlbumShare share) {
    if (album.albumFile!.isOwned(account.username)) {
      // album owner
      return item.addedBy == account.username ||
          item.addedAt.isBefore(share.sharedAt);
    } else {
      // non album owner
      if (item.addedBy != account.username) {
        return false;
      } else {
        return share.userId == album.albumFile!.ownerId ||
            !item.addedAt.isBefore(share.sharedAt);
      }
    }
  }

  final DiContainer _c;

  static final _log =
      Logger("bloc.list_album_share_outlier.ListAlbumShareOutlierBloc");
}
