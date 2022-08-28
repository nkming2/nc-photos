import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/location_util.dart' as location_util;

class LocationGroup {
  const LocationGroup(
      this.place, this.countryCode, this.count, this.latestFileId);

  @override
  toString() => "$runtimeType {"
      "place: $place, "
      "countryCode: $countryCode, "
      "count: $count, "
      "latestFileId: $latestFileId, "
      "}";

  final String place;
  final String countryCode;
  final int count;
  final int latestFileId;
}

class LocationGroupResult {
  const LocationGroupResult(
      this.name, this.admin1, this.admin2, this.countryCode);

  @override
  toString() => "$runtimeType {"
      "name: List {length: ${name.length}}, "
      "admin1: List {length: ${admin1.length}}, "
      "admin2: List {length: ${admin2.length}}, "
      "countryCode: List {length: ${countryCode.length}}, "
      "}";

  final List<LocationGroup> name;
  final List<LocationGroup> admin1;
  final List<LocationGroup> admin2;
  final List<LocationGroup> countryCode;
}

class ListLocationGroup {
  ListLocationGroup(this._c) : assert(require(_c));

  static bool require(DiContainer c) => DiContainer.has(c, DiType.sqliteDb);

  /// List location groups based on the name of the places
  Future<LocationGroupResult> call(Account account) async {
    final s = Stopwatch()..start();
    try {
      return await _c.sqliteDb.use((db) async {
        final dbAccount = await db.accountOf(account);

        final nameResult = <LocationGroup>[];
        final admin1Result = <LocationGroup>[];
        final admin2Result = <LocationGroup>[];
        final countryCodeResult = <LocationGroup>[];
        for (final r in account.roots) {
          final latest = db.accountFiles.bestDateTime.max();
          final count = db.imageLocations.rowId.count();
          final nameQ = _buildQuery(
              db, dbAccount, r, latest, count, db.imageLocations.name);
          try {
            nameResult.addAll(await nameQ
                .map((r) => LocationGroup(
                      r.read(db.imageLocations.name)!,
                      r.read(db.imageLocations.countryCode)!,
                      r.read(count),
                      r.read(db.files.fileId)!,
                    ))
                .get());
          } catch (e, stackTrace) {
            _log.shout("[call] Failed while query name group", e, stackTrace);
          }

          final admin1Q = _buildQuery(
              db, dbAccount, r, latest, count, db.imageLocations.admin1);
          try {
            admin1Result.addAll(await admin1Q
                .map((r) => LocationGroup(
                      r.read(db.imageLocations.admin1)!,
                      r.read(db.imageLocations.countryCode)!,
                      r.read(count),
                      r.read(db.files.fileId)!,
                    ))
                .get());
          } catch (e, stackTrace) {
            _log.shout("[call] Failed while query admin1 group", e, stackTrace);
          }

          final admin2Q = _buildQuery(
              db, dbAccount, r, latest, count, db.imageLocations.admin2);
          try {
            admin2Result.addAll(await admin2Q
                .map((r) => LocationGroup(
                      r.read(db.imageLocations.admin2)!,
                      r.read(db.imageLocations.countryCode)!,
                      r.read(count),
                      r.read(db.files.fileId)!,
                    ))
                .get());
          } catch (e, stackTrace) {
            _log.shout("[call] Failed while query admin2 group", e, stackTrace);
          }

          final countryCodeQ = _buildQuery(
              db, dbAccount, r, latest, count, db.imageLocations.countryCode);
          try {
            countryCodeResult.addAll(await countryCodeQ.map((r) {
              final cc = r.read(db.imageLocations.countryCode)!;
              return LocationGroup(location_util.alpha2CodeToName(cc) ?? cc, cc,
                  r.read(count), r.read(db.files.fileId)!);
            }).get());
          } catch (e, stackTrace) {
            _log.shout(
                "[call] Failed while query countryCode group", e, stackTrace);
          }
        }
        return LocationGroupResult(
            nameResult, admin1Result, admin2Result, countryCodeResult);
      });
    } finally {
      _log.info("[call] Elapsed time: ${s.elapsedMilliseconds}ms");
    }
  }

  sql.JoinedSelectStatement _buildQuery(
    sql.SqliteDb db,
    sql.Account dbAccount,
    String dir,
    sql.Expression<DateTime> latest,
    sql.Expression<int> count,
    sql.GeneratedColumn<String?> groupColumn,
  ) {
    final query = db.selectOnly(db.imageLocations).join([
      sql.innerJoin(db.accountFiles,
          db.accountFiles.rowId.equalsExp(db.imageLocations.accountFile),
          useColumns: false),
      sql.innerJoin(db.files, db.files.rowId.equalsExp(db.accountFiles.file),
          useColumns: false),
    ]);
    if (identical(groupColumn, db.imageLocations.countryCode)) {
      query
        ..addColumns([db.imageLocations.countryCode, count, db.files.fileId])
        ..groupBy([db.imageLocations.countryCode],
            having: db.accountFiles.bestDateTime.equalsExp(latest));
    } else {
      query
        ..addColumns([
          groupColumn,
          db.imageLocations.countryCode,
          count,
          db.files.fileId
        ])
        ..groupBy([groupColumn, db.imageLocations.countryCode],
            having: db.accountFiles.bestDateTime.equalsExp(latest));
    }
    query
      ..where(db.accountFiles.account.equals(dbAccount.rowId))
      ..where(groupColumn.isNotNull());
    if (dir.isNotEmpty) {
      query.where(db.accountFiles.relativePath.like("$dir/%"));
    }
    return query;
  }

  final DiContainer _c;

  static final _log = Logger("use_case.list_location_group.ListLocationGroup");
}
