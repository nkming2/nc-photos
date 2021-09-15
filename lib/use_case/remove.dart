import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/throttler.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/use_case/update_album.dart';

class Remove {
  Remove(this.fileRepo, this.albumRepo);

  /// Remove a file
  Future<void> call(Account account, File file) async {
    await fileRepo.remove(account, file);
    if (albumRepo != null) {
      _log.info("[call] Skip albums cleanup as albumRepo == null");
      _CleanUpAlbums()(_CleanUpAlbumsData(fileRepo, albumRepo!, account, file));
    }
    KiwiContainer().resolve<EventBus>().fire(FileRemovedEvent(account, file));
  }

  final FileRepo fileRepo;
  final AlbumRepo? albumRepo;

  static final _log = Logger("use_case.remove.Remove");
}

class _CleanUpAlbumsData {
  _CleanUpAlbumsData(this.fileRepo, this.albumRepo, this.account, this.file);

  final FileRepo fileRepo;
  final AlbumRepo albumRepo;
  final Account account;
  final File file;
}

class _CleanUpAlbums {
  factory _CleanUpAlbums() {
    _inst ??= _CleanUpAlbums._();
    return _inst!;
  }

  _CleanUpAlbums._() {
    _throttler = Throttler<_CleanUpAlbumsData>(
      onTriggered: (data) {
        _onTriggered(data);
      },
      logTag: "remove._CleanUpAlbums",
    );
  }

  void call(_CleanUpAlbumsData data) {
    _throttler.trigger(
      maxResponceTime: const Duration(seconds: 3),
      maxPendingCount: 10,
      data: data,
    );
  }

  void _onTriggered(List<_CleanUpAlbumsData> data) async {
    for (final pair in data.groupBy(key: (e) => e.account)) {
      final list = pair.item2;
      await _cleanUp(list.first.fileRepo, list.first.albumRepo,
          list.first.account, list.map((e) => e.file).toList());
    }
  }

  /// Clean up for a single account
  Future<void> _cleanUp(FileRepo fileRepo, AlbumRepo albumRepo, Account account,
      List<File> removes) async {
    final albums = (await ListAlbum(fileRepo, albumRepo)(account)
            .where((event) => event is Album)
            .toList())
        .cast<Album>();
    // clean up only make sense for static albums
    for (final a
        in albums.where((element) => element.provider is AlbumStaticProvider)) {
      try {
        final provider = AlbumStaticProvider.of(a);
        if (provider.items.whereType<AlbumFileItem>().any((element) =>
            removes.containsIf(element.file, (a, b) => a.path == b.path))) {
          final newItems = provider.items.where((element) {
            if (element is AlbumFileItem) {
              return !removes.containsIf(
                  element.file, (a, b) => a.path == b.path);
            } else {
              return true;
            }
          }).toList();
          await UpdateAlbum(albumRepo)(
              account,
              a.copyWith(
                provider: AlbumStaticProvider(
                  items: newItems,
                ),
              ));
        }
      } catch (e, stacktrace) {
        _log.shout(
            "[_cleanUpAlbums] Failed while updating album", e, stacktrace);
        // continue to next album
      }
    }
  }

  late final Throttler<_CleanUpAlbumsData> _throttler;

  static final _log = Logger("use_case.remove");

  static _CleanUpAlbums? _inst;
}
