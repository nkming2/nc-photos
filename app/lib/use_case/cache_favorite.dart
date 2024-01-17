import 'package:event_bus/event_bus.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/db/entity_converter.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/event/event.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_db/np_db.dart';

part 'cache_favorite.g.dart';

@npLog
class CacheFavorite {
  const CacheFavorite(this._c);

  /// Cache favorites using results from remote
  ///
  /// Return the fileIds of the affected files
  Future<DbSyncIdResult> call(
      Account account, Iterable<int> remoteFileIds) async {
    _log.info("[call] Cache favorites");
    final result = await _c.npDb.syncFavoriteFiles(
      account: account.toDb(),
      favoriteFileIds: remoteFileIds.toList(),
    );
    if (result.isNotEmpty) {
      KiwiContainer().resolve<EventBus>().fire(FavoriteResyncedEvent(account));
    }
    return result;
  }

  final DiContainer _c;
}
