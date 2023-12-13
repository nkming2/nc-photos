import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/db/entity_converter.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/event/event.dart';
import 'package:np_codegen/np_codegen.dart';

part 'cache_favorite.g.dart';

@npLog
class CacheFavorite {
  const CacheFavorite(this._c);

  /// Cache favorites using results from remote
  ///
  /// Return number of files updated
  Future<int> call(Account account, Iterable<int> remoteFileIds) async {
    _log.info("[call] Cache favorites");
    final result = await _c.npDb.syncFavoriteFiles(
      account: account.toDb(),
      favoriteFileIds: remoteFileIds.toList(),
    );
    final count = result.insert + result.delete + result.update;
    if (count > 0) {
      KiwiContainer().resolve<EventBus>().fire(FavoriteResyncedEvent(account));
    }
    return count;
  }

  final DiContainer _c;
}
