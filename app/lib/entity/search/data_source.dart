import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/search.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/object_extension.dart';

class SearchSqliteDbDataSource implements SearchDataSource {
  SearchSqliteDbDataSource(this.sqliteDb);

  @override
  list(Account account, SearchCriteria criteria) async {
    _log.info("[list] $criteria");
    final keywords =
        criteria.keywords.map((e) => e.toCaseInsensitiveString()).toList();
    final dbFiles = await sqliteDb.use((db) async {
      final query = db.queryFiles().run((q) {
        q.setQueryMode(sql.FilesQueryMode.completeFile);
        q.setAppAccount(account);
        for (final r in account.roots) {
          if (r.isNotEmpty) {
            q.byOrRelativePathPattern("$r/%");
          }
        }
        for (final f in criteria.filters) {
          f.apply(q);
        }
        return q.build();
      });
      // limit to supported formats only
      query.where(db.files.contentType.like("image/%") |
          db.files.contentType.like("video/%"));
      for (final k in keywords) {
        query.where(db.accountFiles.relativePath.like("%$k%"));
      }
      return await query
          .map((r) => sql.CompleteFile(
                r.readTable(db.files),
                r.readTable(db.accountFiles),
                r.readTableOrNull(db.images),
                r.readTableOrNull(db.trashes),
              ))
          .get();
    });
    return await dbFiles.convertToAppFile(account);
  }

  final sql.SqliteDb sqliteDb;

  static final _log =
      Logger("entity.search.data_source.SearchSqliteDbDataSource");
}
