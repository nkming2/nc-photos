import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/use_case/list_tagged_file.dart';
import 'package:nc_photos/use_case/scan_dir.dart';

class PopulateAlbum {
  PopulateAlbum(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.fileRepo);

  Future<List<AlbumItem>> call(Account account, Album album) async {
    if (album.provider is AlbumStaticProvider) {
      _log.warning(
          "[call] Populate only make sense for dynamic albums: ${album.name}");
      return AlbumStaticProvider.of(album).items;
    } else if (album.provider is AlbumDirProvider) {
      return _populateDirAlbum(account, album);
    } else if (album.provider is AlbumTagProvider) {
      return _populateTagAlbum(account, album);
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
      final stream = ScanDir(_c.fileRepo)(account, d);
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

  Future<List<AlbumItem>> _populateTagAlbum(
      Account account, Album album) async {
    assert(album.provider is AlbumTagProvider);
    final provider = album.provider as AlbumTagProvider;
    final products = <AlbumItem>[];
    final c = KiwiContainer().resolve<DiContainer>();
    final files = await ListTaggedFile(c)(account, provider.tags);
    products.addAll(files.map((f) => AlbumFileItem(
          addedBy: account.username,
          addedAt: DateTime.now(),
          file: f,
        )));
    return products;
  }

  Future<List<AlbumItem>> _populateMemoryAlbum(
      Account account, Album album) async {
    assert(album.provider is AlbumMemoryProvider);
    final provider = album.provider as AlbumMemoryProvider;
    final date = DateTime(provider.year, provider.month, provider.day);
    final from = date.subtract(const Duration(days: 2));
    final to = date.add(const Duration(days: 3));
    final files = await FileSqliteDbDataSource(_c).listByDate(
        account, from.millisecondsSinceEpoch, to.millisecondsSinceEpoch);
    return files
        .where((f) => file_util.isSupportedFormat(f))
        .map((f) => AlbumFileItem(
              addedBy: account.username,
              addedAt: DateTime.now(),
              file: f,
            ))
        .toList();
  }

  final DiContainer _c;

  static final _log = Logger("use_case.populate_album.PopulateAlbum");
}
