part of '../database.dart';

extension SqliteDbNcAlbumExtension on SqliteDb {
  Future<List<NcAlbum>> ncAlbumsByAccount({
    required ByAccount account,
  }) {
    assert((account.sqlAccount != null) != (account.appAccount != null));
    if (account.sqlAccount != null) {
      final query = select(ncAlbums)
        ..where((t) => t.account.equals(account.sqlAccount!.rowId));
      return query.get();
    } else {
      final query = select(ncAlbums).join([
        innerJoin(accounts, accounts.rowId.equalsExp(ncAlbums.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(account.appAccount!.url))
        ..where(accounts.userId
            .equals(account.appAccount!.userId.toCaseInsensitiveString()));
      return query.map((r) => r.readTable(ncAlbums)).get();
    }
  }

  Future<List<List>> partialNcAlbumsByAccount({
    required ByAccount account,
    required List<Expression> columns,
  }) {
    final query = selectOnly(ncAlbums)..addColumns(columns);
    if (account.sqlAccount != null) {
      query.where(ncAlbums.account.equals(account.sqlAccount!.rowId));
    } else {
      query.join([
        innerJoin(accounts, accounts.rowId.equalsExp(ncAlbums.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(account.appAccount!.url))
        ..where(accounts.userId
            .equals(account.appAccount!.userId.toCaseInsensitiveString()));
    }
    return query.map((r) => columns.map((c) => r.read(c)).toList()).get();
  }

  Future<NcAlbum?> ncAlbumByRelativePath({
    required ByAccount account,
    required String relativePath,
  }) {
    if (account.sqlAccount != null) {
      final query = select(ncAlbums)
        ..where((t) => t.account.equals(account.sqlAccount!.rowId))
        ..where((t) => t.relativePath.equals(relativePath));
      return query.getSingleOrNull();
    } else {
      final query = select(ncAlbums).join([
        innerJoin(accounts, accounts.rowId.equalsExp(ncAlbums.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(account.appAccount!.url))
        ..where(accounts.userId
            .equals(account.appAccount!.userId.toCaseInsensitiveString()))
        ..where(ncAlbums.relativePath.equals(relativePath));
      return query.map((r) => r.readTable(ncAlbums)).getSingleOrNull();
    }
  }

  Future<void> insertNcAlbum({
    required ByAccount account,
    required NcAlbumsCompanion object,
  }) async {
    final Account dbAccount;
    if (account.sqlAccount != null) {
      dbAccount = account.sqlAccount!;
    } else {
      dbAccount = await accountOf(account.appAccount!);
    }
    await into(ncAlbums).insert(object.copyWith(
      account: Value(dbAccount.rowId),
    ));
  }

  /// Delete [NaAlbum] by relativePath
  ///
  /// Return the number of deleted rows
  Future<int> deleteNcAlbumByRelativePath({
    required ByAccount account,
    required String relativePath,
  }) async {
    final Account dbAccount;
    if (account.sqlAccount != null) {
      dbAccount = account.sqlAccount!;
    } else {
      dbAccount = await accountOf(account.appAccount!);
    }
    return await (delete(ncAlbums)
          ..where((t) => t.account.equals(dbAccount.rowId))
          ..where((t) => t.relativePath.equals(relativePath)))
        .go();
  }

  Future<List<NcAlbumItem>> ncAlbumItemsByParent({
    required NcAlbum parent,
  }) {
    final query = select(ncAlbumItems)
      ..where((t) => t.parent.equals(parent.rowId));
    return query.get();
  }

  Future<List<NcAlbumItem>> ncAlbumItemsByParentRelativePath({
    required ByAccount account,
    required String parentRelativePath,
  }) {
    final query = select(ncAlbumItems).join([
      innerJoin(ncAlbums, ncAlbums.rowId.equalsExp(ncAlbumItems.parent),
          useColumns: false),
    ]);
    if (account.sqlAccount != null) {
      query.where(ncAlbums.account.equals(account.sqlAccount!.rowId));
    } else {
      query.join([
        innerJoin(accounts, accounts.rowId.equalsExp(ncAlbums.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(account.appAccount!.url))
        ..where(accounts.userId
            .equals(account.appAccount!.userId.toCaseInsensitiveString()));
    }
    query.where(ncAlbums.relativePath.equals(parentRelativePath));
    return query.map((r) => r.readTable(ncAlbumItems)).get();
  }
}
