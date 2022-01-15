import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/use_case/scan_dir.dart';

class PopulateAlbum {
  const PopulateAlbum(this.appDb);

  Future<List<AlbumItem>> call(Account account, Album album) async {
    if (album.provider is AlbumStaticProvider) {
      _log.warning(
          "[call] Populate only make sense for dynamic albums: ${album.name}");
      return AlbumStaticProvider.of(album).items;
    } else if (album.provider is AlbumDirProvider) {
      return _populateDirAlbum(account, album);
    } else if (album.provider is AlbumMemoryProvider) {
      return _populateMemoryAlbum(account, album);
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
      final stream = ScanDir(FileRepo(FileCachedDataSource(appDb)))(account, d);
      await for (final result in stream) {
        if (result is ExceptionEvent) {
          _log.shout(
              "[_populateDirAlbum] Failed while scanning dir: ${logFilename(d.path)}",
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

  Future<List<AlbumItem>> _populateMemoryAlbum(
      Account account, Album album) async {
    assert(album.provider is AlbumMemoryProvider);
    final provider = album.provider as AlbumMemoryProvider;
    final date = DateTime(provider.year, provider.month, provider.day);
    final from = date.subtract(const Duration(days: 2));
    final to = date.add(const Duration(days: 3));
    final files = await FileAppDbDataSource(appDb).listByDate(account,
        from.millisecondsSinceEpoch, to.millisecondsSinceEpoch);
    return files
        .where((f) => file_util.isSupportedFormat(f))
        .map((f) => AlbumFileItem(
              addedBy: account.username,
              addedAt: DateTime.now(),
              file: f,
            ))
        .toList();
  }

  final AppDb appDb;

  static final _log = Logger("use_case.populate_album.PopulateAlbum");
}
