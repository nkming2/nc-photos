import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart' as app;
import 'package:nc_photos/entity/file.dart' as app;
import 'package:nc_photos/entity/file_descriptor.dart' as app;
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/sqlite/files_query_builder.dart';
import 'package:nc_photos/entity/sqlite/isolate_util.dart';
import 'package:nc_photos/entity/sqlite/table.dart';
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/future_extension.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:np_codegen/np_codegen.dart';
import 'package:np_collection/np_collection.dart';
import 'package:np_platform_lock/np_platform_lock.dart';

part 'database.g.dart';
part 'database/nc_album_extension.dart';
part 'database_extension.dart';

// remember to also update the truncate method after adding a new table
@npLog
@DriftDatabase(
  tables: [
    Servers,
    Accounts,
    Files,
    Images,
    ImageLocations,
    Trashes,
    AccountFiles,
    DirFiles,
    Albums,
    AlbumShares,
    Tags,
    FaceRecognitionPersons,
    NcAlbums,
    NcAlbumItems,
    RecognizeFaces,
    RecognizeFaceItems,
  ],
)
class SqliteDb extends _$SqliteDb {
  SqliteDb({
    QueryExecutor? executor,
  }) : super(executor ?? platform.openSqliteConnection());

  @override
  get schemaVersion => 6;

  @override
  get migration => MigrationStrategy(
        onCreate: (m) async {
          await customStatement("PRAGMA journal_mode=WAL;");
          await m.createAll();

          await m.createIndex(Index("files_server_index",
              "CREATE INDEX files_server_index ON files(server);"));
          await m.createIndex(Index("files_file_id_index",
              "CREATE INDEX files_file_id_index ON files(file_id);"));
          await m.createIndex(Index("files_content_type_index",
              "CREATE INDEX files_content_type_index ON files(content_type);"));

          await m.createIndex(Index("account_files_file_index",
              "CREATE INDEX account_files_file_index ON account_files(file);"));
          await m.createIndex(Index("account_files_relative_path_index",
              "CREATE INDEX account_files_relative_path_index ON account_files(relative_path);"));
          await m.createIndex(Index("account_files_best_date_time_index",
              "CREATE INDEX account_files_best_date_time_index ON account_files(best_date_time);"));

          await m.createIndex(Index("dir_files_dir_index",
              "CREATE INDEX dir_files_dir_index ON dir_files(dir);"));
          await m.createIndex(Index("dir_files_child_index",
              "CREATE INDEX dir_files_child_index ON dir_files(child);"));

          await m.createIndex(Index("album_shares_album_index",
              "CREATE INDEX album_shares_album_index ON album_shares(album);"));

          await _createIndexV2(m);
          await _createIndexV3(m);
        },
        onUpgrade: (m, from, to) async {
          _log.info("[onUpgrade] $from -> $to");
          try {
            await transaction(() async {
              if (from < 2) {
                await m.createTable(tags);
                await m.createTable(faceRecognitionPersons);
                await _createIndexV2(m);
              }
              if (from < 3) {
                await m.createTable(imageLocations);
                await _createIndexV3(m);
              }
              if (from < 4) {
                await m.addColumn(albums, albums.fileEtag);
              }
              if (from < 5) {
                await m.createTable(ncAlbums);
                await m.createTable(ncAlbumItems);
              }
              if (from < 6) {
                if (from >= 2) {
                  await m.renameTable(faceRecognitionPersons, "persons");
                }
                await m.createTable(recognizeFaces);
                await m.createTable(recognizeFaceItems);
              }
            });
          } catch (e, stackTrace) {
            _log.shout("[onUpgrade] Failed upgrading sqlite db", e, stackTrace);
            rethrow;
          }
        },
        beforeOpen: (details) async {
          await customStatement("PRAGMA foreign_keys = ON;");
          // technically we have a platform side lock to ensure only one
          // transaction is running in any isolates, but for some reason we are
          // still seeing database is locked error in crashlytics, let see if
          // this helps
          await customStatement("PRAGMA busy_timeout = 5000;");
        },
      );

  Future<void> _createIndexV2(Migrator m) async {
    await m.createIndex(Index("tags_server_index",
        "CREATE INDEX tags_server_index ON tags(server);"));
    await m.createIndex(Index("face_recognition_persons_account_index",
        "CREATE INDEX face_recognition_persons_account_index ON face_recognition_persons(account);"));
  }

  Future<void> _createIndexV3(Migrator m) async {
    await m.createIndex(Index("image_locations_name_index",
        "CREATE INDEX image_locations_name_index ON image_locations(name);"));
    await m.createIndex(Index("image_locations_country_code_index",
        "CREATE INDEX image_locations_country_code_index ON image_locations(country_code);"));
    await m.createIndex(Index("image_locations_admin1_index",
        "CREATE INDEX image_locations_admin1_index ON image_locations(admin1);"));
    await m.createIndex(Index("image_locations_admin2_index",
        "CREATE INDEX image_locations_admin2_index ON image_locations(admin2);"));
  }
}
