part of '../database_extension.dart';

class ImageLocationGroup {
  const ImageLocationGroup({
    required this.place,
    required this.countryCode,
    required this.count,
    required this.latestFileId,
    required this.latestDateTime,
  });

  final String place;
  final String countryCode;
  final int count;
  final int latestFileId;
  final DateTime latestDateTime;
}

extension SqliteDbImageLocationExtension on SqliteDb {
  Future<List<ImageLocationGroup>> groupImageLocationsByName({
    required ByAccount account,
    List<String>? includeRelativeRoots,
    List<String>? excludeRelativeRoots,
  }) {
    _log.info("[groupImageLocationsByName]");
    return _groupImageLocationsBy(
      account: account,
      by: imageLocations.name,
      includeRelativeRoots: includeRelativeRoots,
      excludeRelativeRoots: excludeRelativeRoots,
    );
  }

  Future<List<ImageLocationGroup>> groupImageLocationsByAdmin1({
    required ByAccount account,
    List<String>? includeRelativeRoots,
    List<String>? excludeRelativeRoots,
  }) {
    _log.info("[groupImageLocationsByAdmin1]");
    return _groupImageLocationsBy(
      account: account,
      by: imageLocations.admin1,
      includeRelativeRoots: includeRelativeRoots,
      excludeRelativeRoots: excludeRelativeRoots,
    );
  }

  Future<List<ImageLocationGroup>> groupImageLocationsByAdmin2({
    required ByAccount account,
    List<String>? includeRelativeRoots,
    List<String>? excludeRelativeRoots,
  }) {
    _log.info("[groupImageLocationsByAdmin2]");
    return _groupImageLocationsBy(
      account: account,
      by: imageLocations.admin2,
      includeRelativeRoots: includeRelativeRoots,
      excludeRelativeRoots: excludeRelativeRoots,
    );
  }

  Future<List<ImageLocationGroup>> groupImageLocationsByCountryCode({
    required ByAccount account,
    List<String>? includeRelativeRoots,
    List<String>? excludeRelativeRoots,
  }) {
    _log.info("[groupImageLocationsByCountryCode]");
    final query = selectOnly(imageLocations).join([
      innerJoin(accountFiles,
          accountFiles.rowId.equalsExp(imageLocations.accountFile),
          useColumns: false),
      innerJoin(files, files.rowId.equalsExp(accountFiles.file),
          useColumns: false),
    ]);
    if (account.sqlAccount != null) {
      query.where(accountFiles.account.equals(account.sqlAccount!.rowId));
    } else {
      query.join([
        innerJoin(accounts, accounts.rowId.equalsExp(accountFiles.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(account.dbAccount!.serverAddress))
        ..where(accounts.userId
            .equals(account.dbAccount!.userId.toCaseInsensitiveString()));
    }

    final count = imageLocations.rowId.count();
    final latest = accountFiles.bestDateTime.max();
    query
      ..addColumns([
        imageLocations.countryCode,
        count,
        files.fileId,
        latest,
      ])
      ..groupBy(
        [imageLocations.countryCode],
        having: accountFiles.bestDateTime.equalsExp(latest),
      )
      ..where(imageLocations.countryCode.isNotNull());
    if (includeRelativeRoots != null &&
        includeRelativeRoots.isNotEmpty &&
        includeRelativeRoots.none((r) => r.isEmpty)) {
      final expr = includeRelativeRoots
          .map((r) => accountFiles.relativePath.like("$r/%"))
          .reduce((value, element) => value | element);
      query.where(expr);
    }
    if (excludeRelativeRoots != null) {
      for (final r in excludeRelativeRoots) {
        query.where(accountFiles.relativePath.like("$r/%").not());
      }
    }
    return query.map((r) {
      final cc = r.read(imageLocations.countryCode)!;
      return ImageLocationGroup(
        place: alpha2CodeToName(cc) ?? cc,
        countryCode: cc,
        count: r.read(count)!,
        latestFileId: r.read(files.fileId)!,
        latestDateTime: r.read(latest)!.toUtc(),
      );
    }).get();
  }

  Future<List<ImageLocationGroup>> _groupImageLocationsBy({
    required ByAccount account,
    required GeneratedColumn<String> by,
    List<String>? includeRelativeRoots,
    List<String>? excludeRelativeRoots,
  }) {
    final query = selectOnly(imageLocations).join([
      innerJoin(accountFiles,
          accountFiles.rowId.equalsExp(imageLocations.accountFile),
          useColumns: false),
      innerJoin(files, files.rowId.equalsExp(accountFiles.file),
          useColumns: false),
    ]);
    if (account.sqlAccount != null) {
      query.where(accountFiles.account.equals(account.sqlAccount!.rowId));
    } else {
      query.join([
        innerJoin(accounts, accounts.rowId.equalsExp(accountFiles.account),
            useColumns: false),
        innerJoin(servers, servers.rowId.equalsExp(accounts.server),
            useColumns: false),
      ])
        ..where(servers.address.equals(account.dbAccount!.serverAddress))
        ..where(accounts.userId
            .equals(account.dbAccount!.userId.toCaseInsensitiveString()));
    }

    final count = imageLocations.rowId.count();
    final latest = accountFiles.bestDateTime.max();
    query
      ..addColumns([
        by,
        imageLocations.countryCode,
        count,
        files.fileId,
        latest,
      ])
      ..groupBy(
        [by, imageLocations.countryCode],
        having: accountFiles.bestDateTime.equalsExp(latest),
      )
      ..where(by.isNotNull());
    if (includeRelativeRoots != null &&
        includeRelativeRoots.isNotEmpty &&
        includeRelativeRoots.none((r) => r.isEmpty)) {
      final expr = includeRelativeRoots
          .map((r) => accountFiles.relativePath.like("$r/%"))
          .reduce((value, element) => value | element);
      query.where(expr);
    }
    if (excludeRelativeRoots != null) {
      for (final r in excludeRelativeRoots) {
        query.where(accountFiles.relativePath.like("$r/%").not());
      }
    }
    return query
        .map((r) => ImageLocationGroup(
              place: r.read(by)!,
              countryCode: r.read(imageLocations.countryCode)!,
              count: r.read(count)!,
              latestFileId: r.read(files.fileId)!,
              latestDateTime: r.read(latest)!.toUtc(),
            ))
        .get();
  }
}
