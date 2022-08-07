import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_converter.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/list_util.dart' as list_util;

class SyncTag {
  SyncTag(this._c) : assert(require(_c));

  static bool require(DiContainer c) =>
      DiContainer.has(c, DiType.tagRepoRemote) &&
      DiContainer.has(c, DiType.tagRepoLocal);

  /// Sync tags in cache db with remote server
  Future<void> call(Account account) async {
    _log.info("[call] Sync tags with remote");
    int tagSorter(Tag a, Tag b) => a.id.compareTo(b.id);
    final remote = (await _c.tagRepoRemote.list(account))..sort(tagSorter);
    final cache = (await _c.tagRepoLocal.list(account))..sort(tagSorter);
    final diff = list_util.diffWith<Tag>(cache, remote, tagSorter);
    final inserts = diff.item1;
    _log.info("[call] New tags: ${inserts.toReadableString()}");
    final deletes = diff.item2;
    _log.info("[call] Removed tags: ${deletes.toReadableString()}");
    final updates = remote.where((r) {
      final c = cache.firstWhereOrNull((c) => c.id == r.id);
      return c != null && c != r;
    }).toList();
    _log.info("[call] Updated tags: ${updates.toReadableString()}");

    if (inserts.isNotEmpty || deletes.isNotEmpty || updates.isNotEmpty) {
      await _c.sqliteDb.use((db) async {
        final dbAccount = await db.accountOf(account);
        await db.batch((batch) {
          for (final d in deletes) {
            batch.deleteWhere(
              db.tags,
              (sql.$TagsTable t) =>
                  t.server.equals(dbAccount.server) & t.tagId.equals(d.id),
            );
          }
          for (final u in updates) {
            batch.update(
              db.tags,
              sql.TagsCompanion(
                displayName: sql.Value(u.displayName),
                userVisible: sql.Value(u.userVisible),
                userAssignable: sql.Value(u.userAssignable),
              ),
              where: (sql.$TagsTable t) =>
                  t.server.equals(dbAccount.server) & t.tagId.equals(u.id),
            );
          }
          for (final i in inserts) {
            batch.insert(db.tags, SqliteTagConverter.toSql(dbAccount, i),
                mode: sql.InsertMode.insertOrIgnore);
          }
        });
      });
    }
  }

  final DiContainer _c;

  static final _log = Logger("use_case.sync_tag.SyncTag");
}
