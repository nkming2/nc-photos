import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/stream_extension.dart';
import 'package:nc_photos/use_case/album/list_album.dart';
import 'package:nc_photos/use_case/album/remove_from_album.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/remove_share.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';
import 'package:np_string/np_string.dart';

part 'remove.g.dart';

@npLog
class Remove {
  Remove(this._c)
      : assert(require(_c)),
        assert(ListAlbum.require(_c)),
        assert(ListShare.require(_c)),
        assert(RemoveFromAlbum.require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.fileRepo) &&
      DiContainer.has(c, DiType.shareRepo);

  /// Remove list of [files] and return the removed count
  Future<int> call(
    Account account,
    List<FileDescriptor> files, {
    ErrorWithValueIndexedHandler<FileDescriptor>? onError,
    bool shouldCleanUp = true,
  }) async {
    // need to cleanup first, otherwise we can't unshare the files
    if (!shouldCleanUp) {
      _log.info("[call] Skip album cleanup");
    } else {
      await _cleanUpAlbums(account, files);
    }
    var count = 0;
    for (final pair in files.withIndex()) {
      final i = pair.item1;
      final f = pair.item2;
      try {
        await _c.fileRepo.remove(account, f);
        ++count;
        KiwiContainer().resolve<EventBus>().fire(FileRemovedEvent(account, f));
      } catch (e, stackTrace) {
        _log.severe("[call] Failed while remove: ${logFilename(f.fdPath)}", e,
            stackTrace);
        onError?.call(i, f, e, stackTrace);
      }
    }
    return count;
  }

  Future<void> _cleanUpAlbums(
      Account account, List<FileDescriptor> removes) async {
    final albums = await ListAlbum(_c)(account).whereType<Album>().toList();
    // figure out which files need to be unshared with whom
    final unshares = <FileServerIdentityComparator, Set<CiString>>{};
    // clean up only make sense for static albums
    for (final a in albums.where((a) => a.provider is AlbumStaticProvider)) {
      try {
        final provider = AlbumStaticProvider.of(a);
        final itemsToRemove = provider.items
            .whereType<AlbumFileItem>()
            .where((i) =>
                (i.file.isOwned(account.userId) ||
                    i.addedBy == account.userId) &&
                removes.any((r) => r.compareServerIdentity(i.file)))
            .toList();
        if (itemsToRemove.isEmpty) {
          continue;
        }
        for (final i in itemsToRemove) {
          final key = FileServerIdentityComparator(i.file);
          final value = (a.shares?.map((s) => s.userId).toList() ?? [])
            ..add(a.albumFile!.ownerId!)
            ..remove(account.userId);
          (unshares[key] ??= <CiString>{}).addAll(value);
        }
        _log.fine(
            "[_cleanUpAlbums] Removing from album '${a.name}': ${itemsToRemove.map((e) => e.file.path).toReadableString()}");
        // skip unsharing as we'll handle it ourselves
        await RemoveFromAlbum(_c)(account, a, itemsToRemove,
            shouldUnshare: false);
      } catch (e, stacktrace) {
        _log.shout(
            "[_cleanUpAlbums] Failed while updating album", e, stacktrace);
        // continue to next album
      }
    }

    for (final e in unshares.entries) {
      try {
        final shares = await ListShare(_c)(account, e.key.file);
        for (final s in shares.where((s) => e.value.contains(s.shareWith))) {
          try {
            await RemoveShare(_c.shareRepo)(account, s);
          } catch (e, stackTrace) {
            _log.severe(
                "[_cleanUpAlbums] Failed while RemoveShare: $s", e, stackTrace);
          }
        }
      } catch (e, stackTrace) {
        _log.shout("[_cleanUpAlbums] Failed", e, stackTrace);
      }
    }
  }

  final DiContainer _c;
}
