import 'package:drift/drift.dart';
import 'package:nc_photos/account.dart' as app;
import 'package:nc_photos/entity/file.dart' as app;
import 'package:nc_photos/entity/sqlite_table.dart';
import 'package:nc_photos/entity/sqlite_table_converter.dart';
import 'package:nc_photos/entity/sqlite_table_isolate.dart';
import 'package:nc_photos/future_extension.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;

class CompleteFile {
  const CompleteFile(this.file, this.accountFile, this.image, this.trash);

  final File file;
  final AccountFile accountFile;
  final Image? image;
  final Trash? trash;
}

class CompleteFileCompanion {
  const CompleteFileCompanion(
      this.file, this.accountFile, this.image, this.trash);

  final FilesCompanion file;
  final AccountFilesCompanion accountFile;
  final ImagesCompanion? image;
  final TrashesCompanion? trash;
}

extension CompleteFileListExtension on List<CompleteFile> {
  Future<List<app.File>> convertToAppFile(app.Account account) {
    return map((f) => {
          "homeDir": account.homeDir.toString(),
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
        userId: account.username.toCaseInsensitiveString(),
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
      ..where(
          accounts.userId.equals(account.username.toCaseInsensitiveString()))
      ..limit(1);
    return query.map((r) => r.readTable(accounts)).getSingle();
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
    app.File file, {
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
      if (file.fileId != null) {
        q.byFileId(file.fileId!);
      } else {
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
    app.File file, {
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
      q.byFileIds(fileIds);
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
    final query = queryFiles().run((q) {
      q.setQueryMode(FilesQueryMode.completeFile);
      if (sqlAccount != null) {
        q.setSqlAccount(sqlAccount);
      } else {
        q.setAppAccount(appAccount!);
      }
      q.byFileIds(fileIds);
      return q.build();
    });
    return query
        .map((r) => CompleteFile(
              r.readTable(files),
              r.readTable(accountFiles),
              r.readTableOrNull(images),
              r.readTableOrNull(trashes),
            ))
        .get();
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
              r.readTableOrNull(trashes),
            ))
        .get();
  }
}

enum FilesQueryMode {
  file,
  completeFile,
  expression,
}

/// Build a Files table query
///
/// If you call more than one by* methods, the condition will be added up
/// instead of replaced. No validations will be made to make sure the resulting
/// conditions make sense
class FilesQueryBuilder {
  FilesQueryBuilder(this.db);

  /// Set the query mode
  ///
  /// If [mode] == FilesQueryMode.expression, [expressions] must be defined and
  /// not empty
  void setQueryMode(
    FilesQueryMode mode, {
    Iterable<Expression>? expressions,
  }) {
    assert(
        (mode == FilesQueryMode.expression) != (expressions?.isEmpty != false));
    _queryMode = mode;
    _selectExpressions = expressions;
  }

  void setSqlAccount(Account account) {
    assert(_appAccount == null);
    _sqlAccount = account;
  }

  void setAppAccount(app.Account account) {
    assert(_sqlAccount == null);
    _appAccount = account;
  }

  void setAccountless() {
    assert(_sqlAccount == null && _appAccount == null);
    _isAccountless = true;
  }

  void byRowId(int rowId) {
    _byRowId = rowId;
  }

  void byFileId(int fileId) {
    _byFileId = fileId;
  }

  void byFileIds(Iterable<int> fileIds) {
    _byFileIds = fileIds;
  }

  void byRelativePath(String path) {
    _byRelativePath = path;
  }

  void byRelativePathPattern(String pattern) {
    _byRelativePathPattern = pattern;
  }

  void byMimePattern(String pattern) {
    (_byMimePatterns ??= []).add(pattern);
  }

  void byFavorite(bool favorite) {
    _byFavorite = favorite;
  }

  void byDirRowId(int dirRowId) {
    _byDirRowId = dirRowId;
  }

  void byServerRowId(int serverRowId) {
    _byServerRowId = serverRowId;
  }

  JoinedSelectStatement build() {
    if (_sqlAccount == null && _appAccount == null && !_isAccountless) {
      throw StateError("Invalid query: missing account");
    }
    final dynamic select = _queryMode == FilesQueryMode.expression
        ? db.selectOnly(db.files)
        : db.select(db.files);
    final query = select.join([
      innerJoin(db.accountFiles, db.accountFiles.file.equalsExp(db.files.rowId),
          useColumns: _queryMode == FilesQueryMode.completeFile),
      if (_appAccount != null) ...[
        innerJoin(
            db.accounts, db.accounts.rowId.equalsExp(db.accountFiles.account),
            useColumns: false),
        innerJoin(db.servers, db.servers.rowId.equalsExp(db.accounts.server),
            useColumns: false),
      ],
      if (_byDirRowId != null)
        innerJoin(db.dirFiles, db.dirFiles.child.equalsExp(db.files.rowId),
            useColumns: false),
      if (_queryMode == FilesQueryMode.completeFile) ...[
        leftOuterJoin(
            db.images, db.images.accountFile.equalsExp(db.accountFiles.rowId)),
        leftOuterJoin(db.trashes, db.trashes.file.equalsExp(db.files.rowId)),
      ],
    ]) as JoinedSelectStatement;
    if (_queryMode == FilesQueryMode.expression) {
      query.addColumns(_selectExpressions!);
    }

    if (_sqlAccount != null) {
      query.where(db.accountFiles.account.equals(_sqlAccount!.rowId));
    } else if (_appAccount != null) {
      query
        ..where(db.servers.address.equals(_appAccount!.url))
        ..where(db.accounts.userId
            .equals(_appAccount!.username.toCaseInsensitiveString()));
    }

    if (_byRowId != null) {
      query.where(db.files.rowId.equals(_byRowId));
    }
    if (_byFileId != null) {
      query.where(db.files.fileId.equals(_byFileId));
    }
    if (_byFileIds != null) {
      query.where(db.files.fileId.isIn(_byFileIds!));
    }
    if (_byRelativePath != null) {
      query.where(db.accountFiles.relativePath.equals(_byRelativePath));
    }
    if (_byRelativePathPattern != null) {
      query.where(db.accountFiles.relativePath.like(_byRelativePathPattern!));
    }
    if (_byMimePatterns?.isNotEmpty == true) {
      final expression = _byMimePatterns!.sublist(1).fold<Expression<bool?>>(
          db.files.contentType.like(_byMimePatterns![0]),
          (previousValue, element) =>
              previousValue | db.files.contentType.like(element));
      query.where(expression);
    }
    if (_byFavorite != null) {
      if (_byFavorite!) {
        query.where(db.accountFiles.isFavorite.equals(true));
      } else {
        // null are treated as false
        query.where(db.accountFiles.isFavorite.equals(true).not());
      }
    }
    if (_byDirRowId != null) {
      query.where(db.dirFiles.dir.equals(_byDirRowId));
    }
    if (_byServerRowId != null) {
      query.where(db.files.server.equals(_byServerRowId));
    }
    return query;
  }

  final SqliteDb db;

  FilesQueryMode _queryMode = FilesQueryMode.file;
  Iterable<Expression>? _selectExpressions;

  Account? _sqlAccount;
  app.Account? _appAccount;
  bool _isAccountless = false;

  int? _byRowId;
  int? _byFileId;
  Iterable<int>? _byFileIds;
  String? _byRelativePath;
  String? _byRelativePathPattern;
  List<String>? _byMimePatterns;
  bool? _byFavorite;
  int? _byDirRowId;
  int? _byServerRowId;
}

app.File _covertSqliteDbFile(Map map) {
  final homeDir = map["homeDir"] as String;
  final file = map["completeFile"] as CompleteFile;
  return SqliteFileConverter.fromSql(homeDir, file);
}

CompleteFileCompanion _convertAppFile(Map map) {
  final account = map["account"] as Account?;
  final file = map["file"] as app.File;
  return SqliteFileConverter.toSql(account, file);
}
