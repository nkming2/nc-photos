part of 'database.dart';

const maxByFileIdsSize = 30000;

class CompleteFile {
  const CompleteFile(
      this.file, this.accountFile, this.image, this.imageLocation, this.trash);

  final File file;
  final AccountFile accountFile;
  final Image? image;
  final ImageLocation? imageLocation;
  final Trash? trash;
}

class CompleteFileCompanion {
  const CompleteFileCompanion(
      this.file, this.accountFile, this.image, this.imageLocation, this.trash);

  final FilesCompanion file;
  final AccountFilesCompanion accountFile;
  final ImagesCompanion? image;
  final ImageLocationsCompanion? imageLocation;
  final TrashesCompanion? trash;
}

extension CompleteFileListExtension on List<CompleteFile> {
  Future<List<app.File>> convertToAppFile(app.Account account) {
    return map((f) => {
          "userId": account.userId.toString(),
          "completeFile": f,
        }).computeAll(_covertSqliteDbFile);
  }
}

extension FileListExtension on List<app.File> {
  Future<List<CompleteFileCompanion>> convertToFileCompanion(Account? account) {
    return map((f) => {
          "account": account,
          "file": f,
        }).computeAll(_convertAppFile);
  }
}

class FileDescriptor {
  const FileDescriptor({
    required this.relativePath,
    required this.fileId,
    required this.contentType,
    required this.isArchived,
    required this.isFavorite,
    required this.bestDateTime,
  });

  final String relativePath;
  final int fileId;
  final String? contentType;
  final bool? isArchived;
  final bool? isFavorite;
  final DateTime bestDateTime;
}

extension FileDescriptorListExtension on List<FileDescriptor> {
  List<app.FileDescriptor> convertToAppFileDescriptor(app.Account account) {
    return map((f) =>
            SqliteFileDescriptorConverter.fromSql(account.userId.toString(), f))
        .toList();
  }
}

class AlbumWithShare {
  const AlbumWithShare(this.album, this.share);

  final Album album;
  final AlbumShare? share;
}

class CompleteAlbumCompanion {
  const CompleteAlbumCompanion(this.album, this.albumShares);

  final AlbumsCompanion album;
  final List<AlbumSharesCompanion> albumShares;
}

class AccountFileRowIds {
  const AccountFileRowIds(
      this.accountFileRowId, this.accountRowId, this.fileRowId);

  final int accountFileRowId;
  final int accountRowId;
  final int fileRowId;
}

class AccountFileRowIdsWithFileId {
  const AccountFileRowIdsWithFileId(
      this.accountFileRowId, this.accountRowId, this.fileRowId, this.fileId);

  final int accountFileRowId;
  final int accountRowId;
  final int fileRowId;
  final int fileId;
}

class ByAccount {
  const ByAccount.sql(Account account) : this._(sqlAccount: account);

  const ByAccount.app(app.Account account) : this._(appAccount: account);

  const ByAccount._({
    this.sqlAccount,
    this.appAccount,
  }) : assert((sqlAccount != null) != (appAccount != null));

  final Account? sqlAccount;
  final app.Account? appAccount;
}

extension SqliteDbExtension on SqliteDb {
  /// Start a transaction and run [block]
  ///
  /// The [db] argument passed to [block] is identical to this
  ///
  /// Do NOT call this when using [isolate], call [useInIsolate] instead
  Future<T> use<T>(Future<T> Function(SqliteDb db) block) async {
    return await platform.Lock.synchronized(k.appDbLockId, () async {
      return await transaction(() async {
        return await block(this);
      });
    });
  }

  /// Run [block] after acquiring the database
  ///
  /// The [db] argument passed to [block] is identical to this
  ///
  /// This function does not start a transaction, see [use] instead
  Future<T> useNoTransaction<T>(Future<T> Function(SqliteDb db) block) async {
    return await platform.Lock.synchronized(k.appDbLockId, () async {
      return await block(this);
    });
  }

  /// Start an isolate and run [callback] there, with access to the
  /// SQLite database
  Future<U> isolate<T, U>(T args, ComputeWithDbCallback<T, U> callback) async {
    // we need to acquire the lock here as method channel is not supported in
    // background isolates
    return await platform.Lock.synchronized(k.appDbLockId, () async {
      // in unit tests we use an in-memory db, which mean there's no way to
      // access it in other isolates
      if (platform_k.isUnitTest) {
        return await callback(this, args);
      } else {
        return await computeWithDb(callback, args);
      }
    });
  }

  /// Start a transaction and run [block], this version is suitable to be called
  /// in [isolate]
  ///
  /// See: [use]
  Future<T> useInIsolate<T>(Future<T> Function(SqliteDb db) block) async {
    return await transaction(() async {
      return await block(this);
    });
  }

  Future<void> insertAccountOf(app.Account account) async {
    Server dbServer;
    try {
      dbServer = await into(servers).insertReturning(
        ServersCompanion.insert(
          address: account.url,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    } on StateError catch (_) {
      // already exists
      final query = select(servers)
        ..where((t) => t.address.equals(account.url));
      dbServer = await query.getSingle();
    }
    await into(accounts).insert(
      AccountsCompanion.insert(
        server: dbServer.rowId,
        userId: account.userId.toCaseInsensitiveString(),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<Account> accountOf(app.Account account) {
    final query = select(accounts).join([
      innerJoin(servers, servers.rowId.equalsExp(accounts.server),
          useColumns: false)
    ])
      ..where(servers.address.equals(account.url))
      ..where(accounts.userId.equals(account.userId.toCaseInsensitiveString()))
      ..limit(1);
    return query.map((r) => r.readTable(accounts)).getSingle();
  }

  /// Delete Account by app Account
  ///
  /// If the deleted Account is the last one associated with a Server, then the
  /// Server will also be deleted
  Future<void> deleteAccountOf(app.Account account) async {
    final dbAccount = await accountOf(account);
    _log.info("[deleteAccountOf] Remove account: ${dbAccount.rowId}");
    await (delete(accounts)..where((t) => t.rowId.equals(dbAccount.rowId)))
        .go();
    final accountCountExp =
        accounts.rowId.count(filter: accounts.server.equals(dbAccount.server));
    final accountCountQuery = selectOnly(accounts)
      ..addColumns([accountCountExp]);
    final accountCount =
        await accountCountQuery.map((r) => r.read(accountCountExp)).getSingle();
    _log.info("[deleteAccountOf] Remaining accounts in server: $accountCount");
    if (accountCount == 0) {
      _log.info("[deleteAccountOf] Remove server: ${dbAccount.server}");
      await (delete(servers)..where((t) => t.rowId.equals(dbAccount.server)))
          .go();
    }
    await cleanUpDanglingFiles();
  }

  /// Delete Files without a corresponding entry in AccountFiles
  Future<void> cleanUpDanglingFiles() async {
    final query = selectOnly(files).join([
      leftOuterJoin(accountFiles, accountFiles.file.equalsExp(files.rowId),
          useColumns: false),
    ])
      ..addColumns([files.rowId])
      ..where(accountFiles.relativePath.isNull());
    final fileRowIds = await query.map((r) => r.read(files.rowId)!).get();
    if (fileRowIds.isNotEmpty) {
      _log.info("[cleanUpDanglingFiles] Delete ${fileRowIds.length} files");
      await fileRowIds.withPartitionNoReturn((sublist) async {
        await (delete(files)..where((t) => t.rowId.isIn(sublist))).go();
      }, maxByFileIdsSize);
    }
  }

  FilesQueryBuilder queryFiles() => FilesQueryBuilder(this);

  /// Query File by app File
  ///
  /// Only one of [sqlAccount] and [appAccount] must be passed
  Future<File> fileOf(
    app.File file, {
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    final query = queryFiles().run((q) {
      q.setQueryMode(FilesQueryMode.file);
      if (sqlAccount != null) {
        q.setSqlAccount(sqlAccount);
      } else {
        q.setAppAccount(appAccount!);
      }
      if (file.fileId != null) {
        q.byFileId(file.fileId!);
      } else {
        q.byRelativePath(file.strippedPathWithEmpty);
      }
      return q.build()..limit(1);
    });
    return query.map((r) => r.readTable(files)).getSingle();
  }

  /// Query AccountFiles, Accounts and Files row ID by app File
  ///
  /// Only one of [sqlAccount] and [appAccount] must be passed
  Future<AccountFileRowIds?> accountFileRowIdsOfOrNull(
    app.FileDescriptor file, {
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    final query = queryFiles().run((q) {
      q.setQueryMode(FilesQueryMode.expression, expressions: [
        accountFiles.rowId,
        accountFiles.account,
        accountFiles.file,
      ]);
      if (sqlAccount != null) {
        q.setSqlAccount(sqlAccount);
      } else {
        q.setAppAccount(appAccount!);
      }
      try {
        q.byFileId(file.fdId);
      } catch (_) {
        q.byRelativePath(file.strippedPathWithEmpty);
      }
      return q.build()..limit(1);
    });
    return query
        .map((r) => AccountFileRowIds(
              r.read(accountFiles.rowId)!,
              r.read(accountFiles.account)!,
              r.read(accountFiles.file)!,
            ))
        .getSingleOrNull();
  }

  /// See [accountFileRowIdsOfOrNull]
  Future<AccountFileRowIds> accountFileRowIdsOf(
    app.FileDescriptor file, {
    Account? sqlAccount,
    app.Account? appAccount,
  }) =>
      accountFileRowIdsOfOrNull(file,
              sqlAccount: sqlAccount, appAccount: appAccount)
          .notNull();

  /// Query AccountFiles, Accounts and Files row ID by fileIds
  ///
  /// Returned files are NOT guaranteed to be sorted as [fileIds]
  Future<List<AccountFileRowIdsWithFileId>> accountFileRowIdsByFileIds(
    Iterable<int> fileIds, {
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    return fileIds.withPartition((sublist) {
      final query = queryFiles().run((q) {
        q.setQueryMode(FilesQueryMode.expression, expressions: [
          accountFiles.rowId,
          accountFiles.account,
          accountFiles.file,
          files.fileId,
        ]);
        if (sqlAccount != null) {
          q.setSqlAccount(sqlAccount);
        } else {
          q.setAppAccount(appAccount!);
        }
        q.byFileIds(sublist);
        return q.build();
      });
      return query
          .map((r) => AccountFileRowIdsWithFileId(
                r.read(accountFiles.rowId)!,
                r.read(accountFiles.account)!,
                r.read(accountFiles.file)!,
                r.read(files.fileId)!,
              ))
          .get();
    }, maxByFileIdsSize);
  }

  /// Query CompleteFile by fileId
  ///
  /// Returned files are NOT guaranteed to be sorted as [fileIds]
  Future<List<CompleteFile>> completeFilesByFileIds(
    Iterable<int> fileIds, {
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    return fileIds.withPartition((sublist) {
      final query = queryFiles().run((q) {
        q.setQueryMode(FilesQueryMode.completeFile);
        if (sqlAccount != null) {
          q.setSqlAccount(sqlAccount);
        } else {
          q.setAppAccount(appAccount!);
        }
        q.byFileIds(sublist);
        return q.build();
      });
      return query
          .map((r) => CompleteFile(
                r.readTable(files),
                r.readTable(accountFiles),
                r.readTableOrNull(images),
                r.readTableOrNull(imageLocations),
                r.readTableOrNull(trashes),
              ))
          .get();
    }, maxByFileIdsSize);
  }

  Future<List<CompleteFile>> completeFilesByDirRowId(
    int dirRowId, {
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    final query = queryFiles().run((q) {
      q.setQueryMode(FilesQueryMode.completeFile);
      if (sqlAccount != null) {
        q.setSqlAccount(sqlAccount);
      } else {
        q.setAppAccount(appAccount!);
      }
      q.byDirRowId(dirRowId);
      return q.build();
    });
    return query
        .map((r) => CompleteFile(
              r.readTable(files),
              r.readTable(accountFiles),
              r.readTableOrNull(images),
              r.readTableOrNull(imageLocations),
              r.readTableOrNull(trashes),
            ))
        .get();
  }

  /// Query CompleteFile by favorite
  Future<List<CompleteFile>> completeFilesByFavorite({
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    final query = queryFiles().run((q) {
      q.setQueryMode(FilesQueryMode.completeFile);
      if (sqlAccount != null) {
        q.setSqlAccount(sqlAccount);
      } else {
        q.setAppAccount(appAccount!);
      }
      q.byFavorite(true);
      return q.build();
    });
    return query
        .map((r) => CompleteFile(
              r.readTable(files),
              r.readTable(accountFiles),
              r.readTableOrNull(images),
              r.readTableOrNull(imageLocations),
              r.readTableOrNull(trashes),
            ))
        .get();
  }

  /// Query [FileDescriptor]s by fileId
  ///
  /// Returned files are NOT guaranteed to be sorted as [fileIds]
  Future<List<FileDescriptor>> fileDescriptorsByFileIds(
      ByAccount account, Iterable<int> fileIds) {
    return fileIds.withPartition((sublist) {
      final query = queryFiles().run((q) {
        q.setQueryMode(
          FilesQueryMode.expression,
          expressions: [
            accountFiles.relativePath,
            files.fileId,
            files.contentType,
            accountFiles.isArchived,
            accountFiles.isFavorite,
            accountFiles.bestDateTime,
          ],
        );
        if (account.sqlAccount != null) {
          q.setSqlAccount(account.sqlAccount!);
        } else {
          q.setAppAccount(account.appAccount!);
        }
        q.byFileIds(sublist);
        return q.build();
      });
      return query
          .map((r) => FileDescriptor(
                relativePath: r.read(accountFiles.relativePath)!,
                fileId: r.read(files.fileId)!,
                contentType: r.read(files.contentType),
                isArchived: r.read(accountFiles.isArchived),
                isFavorite: r.read(accountFiles.isFavorite),
                bestDateTime: r.read(accountFiles.bestDateTime)!,
              ))
          .get();
    }, maxByFileIdsSize);
  }

  Future<List<Tag>> allTags({
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    if (sqlAccount != null) {
      final query = select(tags)
        ..where((t) => t.server.equals(sqlAccount.server));
      return query.get();
    } else {
      final query = select(tags).join([
        innerJoin(servers, servers.rowId.equalsExp(tags.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(appAccount!.url));
      return query.map((r) => r.readTable(tags)).get();
    }
  }

  Future<Tag?> tagByDisplayName({
    Account? sqlAccount,
    app.Account? appAccount,
    required String displayName,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    if (sqlAccount != null) {
      final query = select(tags)
        ..where((t) => t.server.equals(sqlAccount.server))
        ..where((t) => t.displayName.like(displayName))
        ..limit(1);
      return query.getSingleOrNull();
    } else {
      final query = select(tags).join([
        innerJoin(servers, servers.rowId.equalsExp(tags.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(appAccount!.url))
        ..where(tags.displayName.like(displayName))
        ..limit(1);
      return query.map((r) => r.readTable(tags)).getSingleOrNull();
    }
  }

  Future<List<Person>> allPersons({
    Account? sqlAccount,
    app.Account? appAccount,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    if (sqlAccount != null) {
      final query = select(persons)
        ..where((t) => t.account.equals(sqlAccount.rowId));
      return query.get();
    } else {
      final query = select(persons).join([
        innerJoin(accounts, accounts.rowId.equalsExp(persons.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(appAccount!.url))
        ..where(accounts.userId
            .equals(appAccount.userId.toCaseInsensitiveString()));
      return query.map((r) => r.readTable(persons)).get();
    }
  }

  Future<List<Person>> personsByName({
    Account? sqlAccount,
    app.Account? appAccount,
    required String name,
  }) {
    assert((sqlAccount != null) != (appAccount != null));
    if (sqlAccount != null) {
      final query = select(persons)
        ..where((t) => t.account.equals(sqlAccount.rowId))
        ..where((t) =>
            t.name.like(name) |
            t.name.like("% $name") |
            t.name.like("$name %"));
      return query.get();
    } else {
      final query = select(persons).join([
        innerJoin(accounts, accounts.rowId.equalsExp(persons.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(appAccount!.url))
        ..where(persons.name.like(name) |
            persons.name.like("% $name") |
            persons.name.like("$name %"));
      return query.map((r) => r.readTable(persons)).get();
    }
  }

  Future<int> countMissingMetadataByFileIds({
    Account? sqlAccount,
    app.Account? appAccount,
    required List<int> fileIds,
  }) async {
    assert((sqlAccount != null) != (appAccount != null));
    if (fileIds.isEmpty) {
      return 0;
    }
    final counts = await fileIds.withPartition((sublist) async {
      final count = countAll(
          filter:
              images.lastUpdated.isNull() | imageLocations.version.isNull());
      final query = selectOnly(files).join([
        innerJoin(accountFiles, accountFiles.file.equalsExp(files.rowId),
            useColumns: false),
        if (appAccount != null) ...[
          innerJoin(accounts, accounts.rowId.equalsExp(accountFiles.account),
              useColumns: false),
          innerJoin(servers, servers.rowId.equalsExp(accounts.server),
              useColumns: false),
        ],
        leftOuterJoin(images, images.accountFile.equalsExp(accountFiles.rowId),
            useColumns: false),
        leftOuterJoin(imageLocations,
            imageLocations.accountFile.equalsExp(accountFiles.rowId),
            useColumns: false),
      ]);
      query.addColumns([count]);
      if (sqlAccount != null) {
        query.where(accountFiles.account.equals(sqlAccount.rowId));
      } else if (appAccount != null) {
        query
          ..where(servers.address.equals(appAccount.url))
          ..where(accounts.userId
              .equals(appAccount.userId.toCaseInsensitiveString()));
      }
      query
        ..where(files.fileId.isIn(sublist))
        ..where(whereFileIsSupportedImageMime());
      return [await query.map((r) => r.read(count)).getSingle()];
    }, maxByFileIdsSize);
    return counts.reduce((value, element) => value + element);
  }

  Future<void> truncate() async {
    await delete(servers).go();
    // technically deleting Servers table is enough to clear the followings, but
    // just in case
    await delete(accounts).go();
    await delete(files).go();
    await delete(images).go();
    await delete(imageLocations).go();
    await delete(trashes).go();
    await delete(accountFiles).go();
    await delete(dirFiles).go();
    await delete(albums).go();
    await delete(albumShares).go();
    await delete(tags).go();
    await delete(persons).go();
    await delete(ncAlbums).go();
    await delete(ncAlbumItems).go();

    // reset the auto increment counter
    await customStatement("UPDATE sqlite_sequence SET seq=0;");
  }

  Expression<bool?> whereFileIsSupportedMime() {
    return file_util.supportedFormatMimes
        .map<Expression<bool?>>((m) => files.contentType.equals(m))
        .reduce((value, element) => value | element);
  }

  Expression<bool?> whereFileIsSupportedImageMime() {
    return file_util.supportedImageFormatMimes
        .map<Expression<bool?>>((m) => files.contentType.equals(m))
        .reduce((value, element) => value | element);
  }
}

app.File _covertSqliteDbFile(Map map) {
  final userId = map["userId"] as String;
  final file = map["completeFile"] as CompleteFile;
  return SqliteFileConverter.fromSql(userId, file);
}

CompleteFileCompanion _convertAppFile(Map map) {
  final account = map["account"] as Account?;
  final file = map["file"] as app.File;
  return SqliteFileConverter.toSql(account, file);
}
