import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/use_case/scan_dir.dart';

class PopulateAlbum {
  Future<List<AlbumItem>> call(Account account, Album album) async {
    if (album.provider is AlbumStaticProvider) {
      _log.warning(
          "[call] Populate only make sense for dynamic albums: ${album.name}");
      return AlbumStaticProvider.of(album).items;
    }
    if (album.provider is AlbumDirProvider) {
      return _populateDirAlbum(account, album);
    } else {
      throw ArgumentError(
          "Unknown album provider: ${album.provider.runtimeType}");
    }
  }

  Future<List<AlbumItem>> _populateDirAlbum(
      Account account, Album album) async {
    assert(album.provider is AlbumDirProvider);
    final provider = album.provider as AlbumDirProvider;
    final products = <AlbumItem>[];
    for (final d in provider.dirs) {
      final stream = ScanDir(FileRepo(FileCachedDataSource()))(account, d);
      await for (final result in stream) {
        if (result is ExceptionEvent) {
          _log.shout(
              "[_populateDirAlbum] Failed while scanning dir" +
                  (shouldLogFileName ? ": $d" : ""),
              result.error,
              result.stackTrace);
          continue;
        }
        products.addAll((result as List).cast<File>().map((f) => AlbumFileItem(
              addedBy: account.username,
              addedAt: DateTime.now(),
              file: f,
            )));
      }
    }
    return products;
  }

  static final _log = Logger("use_case.populate_album.PopulateAlbum");
}
