import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/use_case/find_file.dart';
import 'package:np_codegen/np_codegen.dart';

part 'list_favorite.g.dart';

@npLog
class ListFavorite {
  ListFavorite(this._c)
      : assert(require(_c)),
        assert(FindFile.require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.favoriteRepo);

  /// List all favorites for [account]
  Future<List<File>> call(Account account) async {
    final favorites = <Favorite>[];
    for (final r in account.roots) {
      favorites.addAll(await _c.favoriteRepo
          .list(account, File(path: file_util.unstripPath(account, r))));
    }
    final files = await FindFile(_c)(
      account,
      favorites.map((f) => f.fileId).toList(),
      onFileNotFound: (id) {
        // ignore missing file
        _log.warning("[call] Missing file: $id");
      },
    );
    return files
        .where((f) => file_util.isSupportedFormat(f))
        // The file in AppDb may not be marked as favorite correctly
        .map((f) => f.copyWith(isFavorite: true))
        .toList();
  }

  final DiContainer _c;
}
