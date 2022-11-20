import 'package:drift/drift.dart' as sql;
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sqlite_table_converter.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/location_util.dart' as location_util;
import 'package:nc_photos/object_extension.dart';

class ListLocationFile {
  ListLocationFile(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// List all files located in [place], [countryCode]
  Future<List<File>> call(
      Account account, File dir, String? place, String countryCode) async {
    final dbFiles = await _c.sqliteDb.use((db) async {
      final query = db.queryFiles().run((q) {
        q
          ..setQueryMode(sql.FilesQueryMode.completeFile)
          ..setAppAccount(account);
        dir.strippedPathWithEmpty.run((p) {
          if (p.isNotEmpty) {
            q.byOrRelativePathPattern("$p/%");
          }
        });
        return q.build();
      });
      if (place == null ||
          location_util.alpha2CodeToName(countryCode) == place) {
        // some places in the DB have the same name as the country, in such
        // cases, we return all photos from the country
        query.where(db.imageLocations.countryCode.equals(countryCode));
      } else {
        query
          ..where(db.imageLocations.name.equals(place) |
              db.imageLocations.admin1.equals(place) |
              db.imageLocations.admin2.equals(place))
          ..where(db.imageLocations.countryCode.equals(countryCode));
      }
      return await query
          .map((r) => sql.CompleteFile(
                r.readTable(db.files),
                r.readTable(db.accountFiles),
                r.readTableOrNull(db.images),
                r.readTableOrNull(db.imageLocations),
                r.readTableOrNull(db.trashes),
              ))
          .get();
    });
    return dbFiles
        .map((f) => SqliteFileConverter.fromSql(account.userId.toString(), f))
        .toList();
  }

  final DiContainer _c;
}
