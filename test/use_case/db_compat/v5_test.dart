import 'package:idb_shim/idb_client.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/use_case/db_compat/v5.dart';
import 'package:test/test.dart';

import '../../mock_type.dart';
import '../../test_util.dart' as util;

void main() {
  group("DbCompatV5", () {
    group("isNeedMigration", () {
      test("w/ meta entry == false", () async {
        final appDb = MockAppDb();
        await appDb.use((db) async {
          final transaction =
              db.transaction(AppDb.metaStoreName, idbModeReadWrite);
          final metaStore = transaction.objectStore(AppDb.metaStoreName);
          const entry = AppDbMetaEntryDbCompatV5(false);
          await metaStore.put(entry.toEntry().toJson());
        });

        expect(await DbCompatV5.isNeedMigration(appDb), true);
      });

      test("w/ meta entry == true", () async {
        final appDb = MockAppDb();
        await appDb.use((db) async {
          final transaction =
              db.transaction(AppDb.metaStoreName, idbModeReadWrite);
          final metaStore = transaction.objectStore(AppDb.metaStoreName);
          const entry = AppDbMetaEntryDbCompatV5(true);
          await metaStore.put(entry.toEntry().toJson());
        });

        expect(await DbCompatV5.isNeedMigration(appDb), false);
      });

      test("w/o meta entry", () async {
        final appDb = MockAppDb();
        await appDb.use((db) async {
          final transaction =
              db.transaction(AppDb.metaStoreName, idbModeReadWrite);
          final metaStore = transaction.objectStore(AppDb.metaStoreName);
          const entry = AppDbMetaEntryDbCompatV5(true);
          await metaStore.put(entry.toEntry().toJson());
        });

        expect(await DbCompatV5.isNeedMigration(appDb), false);
      });
    });

    test("migrate", () async {
      final account = util.buildAccount();
      final files = (util.FilesBuilder()
            ..addJpeg(
              "admin/test1.jpg",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5),
            ))
          .build();
      final appDb = MockAppDb();
      await appDb.use((db) async {
        final transaction =
            db.transaction(AppDb.file2StoreName, idbModeReadWrite);
        final fileStore = transaction.objectStore(AppDb.file2StoreName);
        await fileStore.put({
          "server": account.url,
          "userId": account.username.toCaseInsensitiveString(),
          "strippedPath": files[0].strippedPathWithEmpty,
          "file": files[0].toJson(),
        }, "${account.url}/${account.username.toCaseInsensitiveString()}/${files[0].fileId}");
      });
      await DbCompatV5.migrate(appDb);

      final objs =
          await util.listAppDb(appDb, AppDb.file2StoreName, (item) => item);
      expect(objs, [
        {
          "server": account.url,
          "userId": account.username.toCaseInsensitiveString(),
          "strippedPath": files[0].strippedPathWithEmpty,
          "dateTimeEpochMs": 1577934245000,
          "file": files[0].toJson(),
        }
      ]);
    });
  });
}
