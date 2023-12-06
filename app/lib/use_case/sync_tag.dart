import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/db/entity_converter.dart';
import 'package:nc_photos/di_container.dart';
import 'package:np_codegen/np_codegen.dart';

part 'sync_tag.g.dart';

@npLog
class SyncTag {
  const SyncTag(this._c);

  /// Sync tags in cache db with remote server
  Future<void> call(Account account) async {
    _log.info("[call] Sync tags with remote");
    final remote = await _c.tagRepoRemote.list(account);
    await _c.npDb.syncTags(
      account: account.toDb(),
      tags: remote.map(DbTagConverter.toDb).toList(),
    );
  }

  final DiContainer _c;
}
