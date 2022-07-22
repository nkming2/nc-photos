import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/override_comparator.dart';
import 'package:nc_photos/use_case/create_share.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/preprocess_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_album_with_actual_items.dart';

class AddToAlbum {
  AddToAlbum(this._c)
      : assert(require(_c)),
        assert(ListShare.require(_c)),
        assert(PreProcessAlbum.require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.albumRepo) &&
      DiContainer.has(c, DiType.shareRepo);

  /// Add a list of AlbumItems to [album]
  Future<Album> call(
      Account account, Album album, List<AlbumItem> items) async {
    _log.info("[call] Add ${items.length} items to album '${album.name}'");
    assert(album.provider is AlbumStaticProvider);
    // resync is needed to work out album cover and latest item
    final oldItems = await PreProcessAlbum(_c)(account, album);
    final itemSet = oldItems
        .map((e) => OverrideComparator<AlbumItem>(
            e, _isItemFileEqual, _getItemHashCode))
        .toSet();
    // find the items that are not having the same file as any existing ones
    final addItems = items
        .where((i) => itemSet.add(OverrideComparator<AlbumItem>(
            i, _isItemFileEqual, _getItemHashCode)))
        .toList();
    if (addItems.isEmpty) {
      return album;
    }
    final newItems = <AlbumItem>[...addItems, ...oldItems];
    var newAlbum = album.copyWith(
      provider: AlbumStaticProvider.of(album).copyWith(
        items: newItems,
      ),
    );
    // UpdateAlbumWithActualItems only persists when there are changes to
    // several properties, so we can't rely on it
    newAlbum = await UpdateAlbumWithActualItems(null)(
      account,
      newAlbum,
      newItems,
    );
    await UpdateAlbum(_c.albumRepo)(account, newAlbum);

    if (album.shares?.isNotEmpty == true) {
      final newFiles =
          addItems.whereType<AlbumFileItem>().map((e) => e.file).toList();
      if (newFiles.isNotEmpty) {
        await _shareFiles(account, newAlbum, newFiles);
      }
    }

    return newAlbum;
  }

  Future<void> _shareFiles(
      Account account, Album album, List<File> files) async {
    final albumShares = (album.shares!.map((e) => e.userId).toList()
          ..add(album.albumFile!.ownerId ?? account.username))
        .where((element) => element != account.username)
        .toSet();
    if (albumShares.isEmpty) {
      return;
    }
    for (final f in files) {
      try {
        final fileShares = (await ListShare(_c)(account, f))
            .where((element) => element.shareType == ShareType.user)
            .map((e) => e.shareWith!)
            .toSet();
        final diffShares = albumShares.difference(fileShares);
        for (final s in diffShares) {
          if (s == f.ownerId) {
            // skip files already owned by the target user
            continue;
          }
          try {
            await CreateUserShare(_c.shareRepo)(account, f, s.raw);
          } catch (e, stackTrace) {
            _log.shout(
                "[_shareFiles] Failed while CreateUserShare: ${logFilename(f.path)}",
                e,
                stackTrace);
          }
        }
      } catch (e, stackTrace) {
        _log.shout(
            "[_shareFiles] Failed while listing shares: ${logFilename(f.path)}",
            e,
            stackTrace);
      }
    }
  }

  final DiContainer _c;

  static final _log = Logger("use_case.add_to_album.AddToAlbum");
}

bool _isItemFileEqual(AlbumItem a, AlbumItem b) {
  if (a is! AlbumFileItem || b is! AlbumFileItem) {
    return false;
  } else {
    return a.file.compareServerIdentity(b.file);
  }
}

int _getItemHashCode(AlbumItem a) {
  if (a is AlbumFileItem) {
    return a.file.fileId?.hashCode ?? a.file.path.hashCode;
  } else {
    return a.hashCode;
  }
}
