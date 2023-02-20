import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;

class ListFavoriteOffline {
  ListFavoriteOffline(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// List all favorites for [account] from the local DB
  Future<List<File>> call(Account account) async {
    final dbFiles = await _c.sqliteDb.use((db) async {
      return await db.completeFilesByFavorite(appAccount: account);
    });
    return await dbFiles.convertToAppFile(account);
  }

  final DiContainer _c;
}
