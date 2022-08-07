import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/object_extension.dart';
import 'package:test/test.dart';

import '../test_util.dart' as util;

void main() {
  group("SqliteDbExtension", () {
    group("insertAccountOf", () {
      test("first", _insertAccountFirst);
      test("same server", _insertAccountSameServer);
      test("same account", _insertAccountSameAccount);
    });
    group("deleteAccountOf", () {
      test("normal", _deleteAccount);
      test("same server", _deleteAccountSameServer);
      test("same server shared file", _deleteAccountSameServerSharedFile);
    });
    test("cleanUpDanglingFiles", _cleanUpDanglingFiles);
    test("truncate", _truncate);
  });
}

/// Insert an Account to a empty db
///
/// Expect: Account and Server inserted
Future<void> _insertAccountFirst() async {
  final account = util.buildAccount();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());

  await c.sqliteDb.use((db) async {
    await db.insertAccountOf(account);
  });
  expect(
    await util.listSqliteDbServerAccounts(c.sqliteDb),
    {
      util.SqlAccountWithServer(
        sql.Server(rowId: 1, address: "http://example.com"),
        sql.Account(rowId: 1, server: 1, userId: "admin"),
      ),
    },
  );
}

/// Insert an Account with Server already exists in db
///
/// Expect: Account and Server inserted
Future<void> _insertAccountSameServer() async {
  final account = util.buildAccount();
  final user1Account = util.buildAccount(userId: "user1");
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
  });

  await c.sqliteDb.use((db) async {
    await db.insertAccountOf(user1Account);
  });
  expect(
    await util.listSqliteDbServerAccounts(c.sqliteDb),
    {
      util.SqlAccountWithServer(
        sql.Server(rowId: 1, address: "http://example.com"),
        sql.Account(rowId: 1, server: 1, userId: "admin"),
      ),
      util.SqlAccountWithServer(
        sql.Server(rowId: 1, address: "http://example.com"),
        sql.Account(rowId: 2, server: 1, userId: "user1"),
      ),
    },
  );
}

/// Insert an Account with the same info as another entry
///
/// Expect: Account not inserted
Future<void> _insertAccountSameAccount() async {
  final account = util.buildAccount();
  final account2 = util.buildAccount();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
  });

  await c.sqliteDb.use((db) async {
    await db.insertAccountOf(account2);
  });
  expect(
    await util.listSqliteDbServerAccounts(c.sqliteDb),
    {
      util.SqlAccountWithServer(
        sql.Server(rowId: 1, address: "http://example.com"),
        sql.Account(rowId: 1, server: 1, userId: "admin"),
      ),
    },
  );
}

/// Delete Account
///
/// Expect: Account deleted;
/// Server deleted;
/// Associated Files deleted
Future<void> _deleteAccount() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
  });

  await c.sqliteDb.use((db) async {
    await db.deleteAccountOf(account);
  });
  expect(
    await util.listSqliteDbServerAccounts(c.sqliteDb),
    <util.SqlAccountWithServer>{},
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    <File>{},
  );
}

/// Delete an Account having the same Server as other Accounts
///
/// Expect: Account deleted;
/// Server remained;
/// Associated Files deleted
Future<void> _deleteAccountSameServer() async {
  final account = util.buildAccount();
  final user1Account = util.buildAccount(userId: "user1");
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final user1Files = (util.FilesBuilder(initialFileId: files.length)
        ..addDir("user1", ownerId: "user1")
        ..addJpeg("user1/test2.jpg", ownerId: "user1"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await c.sqliteDb.insertAccountOf(user1Account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);

    await util.insertFiles(c.sqliteDb, user1Account, user1Files);
    await util.insertDirRelation(
        c.sqliteDb, user1Account, user1Files[0], [user1Files[1]]);
  });

  await c.sqliteDb.use((db) async {
    await db.deleteAccountOf(account);
  });
  expect(
    await util.listSqliteDbServerAccounts(c.sqliteDb),
    {
      util.SqlAccountWithServer(
        sql.Server(rowId: 1, address: "http://example.com"),
        sql.Account(rowId: 2, server: 1, userId: "user1"),
      ),
    },
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {...user1Files},
  );
}

/// Delete an Account having the same Server as other Accounts and with files
/// shared between them (i.e., 1 Files to many AccountFiles)
///
/// Expect: Account deleted;
/// Server remained;
/// Associated Shared Files not deleted;
Future<void> _deleteAccountSameServerSharedFile() async {
  final account = util.buildAccount();
  final user1Account = util.buildAccount(userId: "user1");
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final user1Files = (util.FilesBuilder(initialFileId: files.length)
        ..addDir("user1", ownerId: "user1"))
      .build();
  user1Files
      .add(files[0].copyWith(path: "remote.php/dav/files/user1/test1.jpg"));
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await c.sqliteDb.insertAccountOf(user1Account);
    await util.insertFiles(c.sqliteDb, account, files);
    await util.insertDirRelation(c.sqliteDb, account, files[0], [files[1]]);

    await util.insertFiles(c.sqliteDb, user1Account, user1Files);
    await util.insertDirRelation(
        c.sqliteDb, user1Account, user1Files[0], [user1Files[1]]);
  });

  await c.sqliteDb.use((db) async {
    await db.deleteAccountOf(account);
  });
  expect(
    await util.listSqliteDbServerAccounts(c.sqliteDb),
    {
      util.SqlAccountWithServer(
        sql.Server(rowId: 1, address: "http://example.com"),
        sql.Account(rowId: 2, server: 1, userId: "user1"),
      ),
    },
  );
  expect(
    await util.listSqliteDbFiles(c.sqliteDb),
    {...user1Files},
  );
}

/// Clean up Files without an associated entry in AccountFiles
///
/// Expect: Dangling files deleted
Future<void> _cleanUpDanglingFiles() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);

    await c.sqliteDb.applyFuture((db) async {
      await db.into(db.files).insert(sql.FilesCompanion.insert(
            server: 1,
            fileId: files.length,
          ));
    });
  });

  expect(
    await c.sqliteDb.select(c.sqliteDb.files).map((f) => f.fileId).get(),
    [0, 1, 2],
  );
  await c.sqliteDb.use((db) async {
    await db.cleanUpDanglingFiles();
  });
  expect(
    await c.sqliteDb.select(c.sqliteDb.files).map((f) => f.fileId).get(),
    [0, 1],
  );
}

/// Truncate the db
///
/// Expect: All tables emptied;
/// Auto-increment counters reset to 0
Future<void> _truncate() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addDir("admin")
        ..addJpeg("admin/test1.jpg"))
      .build();
  final c = DiContainer(
    sqliteDb: util.buildTestDb(),
  );
  addTearDown(() => c.sqliteDb.close());
  await c.sqliteDb.transaction(() async {
    await c.sqliteDb.insertAccountOf(account);
    await util.insertFiles(c.sqliteDb, account, files);
  });

  await c.sqliteDb.use((db) async {
    await db.truncate();
  });
  await c.sqliteDb.use((db) async {
    final tables = await db
        .customSelect(
            "SELECT name FROM sqlite_schema WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        .map((r) => r.read<String>("name"))
        .get();
    // this check is to make sure that we are testing all tables
    expect(tables.toSet(), {
      "servers",
      "accounts",
      "files",
      "images",
      "trashes",
      "account_files",
      "dir_files",
      "albums",
      "album_shares",
      "tags",
      "persons",
    });
    for (final t in tables) {
      expect(
        await db
            .customSelect("SELECT COUNT(*) AS c FROM $t;")
            .map((r) => r.read<int>("c"))
            .getSingle(),
        0,
        reason: "Table '$t' is not empty",
      );
    }
    expect(
      (await db
              .customSelect("SELECT seq FROM sqlite_sequence;")
              .map((r) => r.read<int>("seq"))
              .get())
          .every((e) => e == 0),
      true,
    );
  });
}
