import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/use_case/cache_favorite.dart';
import 'package:nc_photos/use_case/list_favorite.dart';

class SyncFavorite {
  SyncFavorite(this._c)
      : assert(require(_c)),
        assert(CacheFavorite.require(_c)),
        assert(ListFavorite.require(_c));

  static bool require(DiContainer c) => true;

  /// Sync favorites in AppDb with remote server
  Future<void> call(Account account) async {
    _log.info("[call] Sync favorites with remote");
    final remote = await ListFavorite(_c)(account);
    await CacheFavorite(_c)(account, remote);
  }

  final DiContainer _c;

  static final _log = Logger("use_case.sync_favorite.SyncFavorite");
}
