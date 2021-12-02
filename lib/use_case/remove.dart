import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/find_file.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/use_case/list_share.dart';
import 'package:nc_photos/use_case/remove_from_album.dart';
import 'package:nc_photos/use_case/remove_share.dart';

class Remove {
  const Remove(
      this.fileRepo, this.albumRepo, this.shareRepo, this.appDb, this.pref)
      : assert(albumRepo == null ||
            (shareRepo != null && appDb != null && pref != null));

  /// Remove files
  Future<void> call(
    Account account,
    List<File> files, {
    void Function(File file, Object error, StackTrace stackTrace)?
        onRemoveFileFailed,
  }) async {
    // need to cleanup first, otherwise we can't unshare the files
    if (albumRepo == null) {
      _log.info("[call] Skip album cleanup as albumRepo == null");
    } else {
      await _cleanUpAlbums(account, files);
    }
    for (final f in files) {
      try {
        await fileRepo.remove(account, f);
        KiwiContainer().resolve<EventBus>().fire(FileRemovedEvent(account, f));
      } catch (e, stackTrace) {
        _log.severe("[call] Failed while remove: ${logFilename(f.path)}", e,
            stackTrace);
        onRemoveFileFailed?.call(f, e, stackTrace);
      }
    }
  }

  Future<void> _cleanUpAlbums(Account account, List<File> removes) async {
    final albums = await ListAlbum(fileRepo, albumRepo!)(account)
        .where((event) => event is Album)
        .cast<Album>()
        .toList();
    // figure out which files need to be unshared with whom
    final unshares = <FileServerIdentityComparator, Set<CiString>>{};
    // clean up only make sense for static albums
    for (final a in albums.where((a) => a.provider is AlbumStaticProvider)) {
      try {
        final provider = AlbumStaticProvider.of(a);
        final itemsToRemove = provider.items
            .whereType<AlbumFileItem>()
            .where((i) =>
                (i.file.isOwned(account.username) ||
                    i.addedBy == account.username) &&
                removes.any((r) => r.compareServerIdentity(i.file)))
            .toList();
        if (itemsToRemove.isEmpty) {
          continue;
        }
        for (final i in itemsToRemove) {
          final key = FileServerIdentityComparator(i.file);
          final value = (a.shares?.map((s) => s.userId).toList() ?? [])
            ..add(a.albumFile!.ownerId!)
            ..remove(account.username);
          (unshares[key] ??= <CiString>{}).addAll(value);
        }
        _log.fine(
            "[_cleanUpAlbums] Removing from album '${a.name}': ${itemsToRemove.map((e) => e.file.path).toReadableString()}");
        // skip unsharing as we'll handle it ourselves
        await RemoveFromAlbum(albumRepo!, null, null, appDb!)(
            account, a, itemsToRemove);
      } catch (e, stacktrace) {
        _log.shout(
            "[_cleanUpAlbums] Failed while updating album", e, stacktrace);
        // continue to next album
      }
    }

    for (final e in unshares.entries) {
      try {
        var file = e.key.file;
        if (file_util.getUserDirName(file) != account.username) {
          try {
            file = await FindFile(appDb!)(account, file.fileId!);
          } catch (_) {
            // file not found
            _log.warning(
                "[_cleanUpAlbums] File not found in db: ${logFilename(file.path)}");
          }
        }
        final shares = await ListShare(shareRepo!)(account, file);
        for (final s in shares.where((s) => e.value.contains(s.shareWith))) {
          try {
            await RemoveShare(shareRepo!)(account, s);
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

  final FileRepo fileRepo;
  final AlbumRepo? albumRepo;
  final ShareRepo? shareRepo;
  final AppDb? appDb;
  final Pref? pref;

  static final _log = Logger("use_case.remove.Remove");
}
