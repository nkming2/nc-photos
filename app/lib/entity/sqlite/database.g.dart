// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: type=lint
class Server extends DataClass implements Insertable<Server> {
  final int rowId;
  final String address;
  Server({required this.rowId, required this.address});
  factory Server.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Server(
      rowId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}row_id'])!,
      address: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}address'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['address'] = Variable<String>(address);
    return map;
  }

  ServersCompanion toCompanion(bool nullToAbsent) {
    return ServersCompanion(
      rowId: Value(rowId),
      address: Value(address),
    );
  }

  factory Server.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Server(
      rowId: serializer.fromJson<int>(json['rowId']),
      address: serializer.fromJson<String>(json['address']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'address': serializer.toJson<String>(address),
    };
  }

  Server copyWith({int? rowId, String? address}) => Server(
        rowId: rowId ?? this.rowId,
        address: address ?? this.address,
      );
  @override
  String toString() {
    return (StringBuffer('Server(')
          ..write('rowId: $rowId, ')
          ..write('address: $address')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, address);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Server &&
          other.rowId == this.rowId &&
          other.address == this.address);
}

class ServersCompanion extends UpdateCompanion<Server> {
  final Value<int> rowId;
  final Value<String> address;
  const ServersCompanion({
    this.rowId = const Value.absent(),
    this.address = const Value.absent(),
  });
  ServersCompanion.insert({
    this.rowId = const Value.absent(),
    required String address,
  }) : address = Value(address);
  static Insertable<Server> custom({
    Expression<int>? rowId,
    Expression<String>? address,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (address != null) 'address': address,
    });
  }

  ServersCompanion copyWith({Value<int>? rowId, Value<String>? address}) {
    return ServersCompanion(
      rowId: rowId ?? this.rowId,
      address: address ?? this.address,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ServersCompanion(')
          ..write('rowId: $rowId, ')
          ..write('address: $address')
          ..write(')'))
        .toString();
  }
}

class $ServersTable extends Servers with TableInfo<$ServersTable, Server> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ServersTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int?> rowId = GeneratedColumn<int?>(
      'row_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _addressMeta = const VerificationMeta('address');
  @override
  late final GeneratedColumn<String?> address = GeneratedColumn<String?>(
      'address', aliasedName, false,
      type: const StringType(),
      requiredDuringInsert: true,
      defaultConstraints: 'UNIQUE');
  @override
  List<GeneratedColumn> get $columns => [rowId, address];
  @override
  String get aliasedName => _alias ?? 'servers';
  @override
  String get actualTableName => 'servers';
  @override
  VerificationContext validateIntegrity(Insertable<Server> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  Server map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Server.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $ServersTable createAlias(String alias) {
    return $ServersTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int rowId;
  final int server;
  final String userId;
  Account({required this.rowId, required this.server, required this.userId});
  factory Account.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Account(
      rowId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}row_id'])!,
      server: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}server'])!,
      userId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['server'] = Variable<int>(server);
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      rowId: Value(rowId),
      server: Value(server),
      userId: Value(userId),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      rowId: serializer.fromJson<int>(json['rowId']),
      server: serializer.fromJson<int>(json['server']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'server': serializer.toJson<int>(server),
      'userId': serializer.toJson<String>(userId),
    };
  }

  Account copyWith({int? rowId, int? server, String? userId}) => Account(
        rowId: rowId ?? this.rowId,
        server: server ?? this.server,
        userId: userId ?? this.userId,
      );
  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('rowId: $rowId, ')
          ..write('server: $server, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, server, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.rowId == this.rowId &&
          other.server == this.server &&
          other.userId == this.userId);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> rowId;
  final Value<int> server;
  final Value<String> userId;
  const AccountsCompanion({
    this.rowId = const Value.absent(),
    this.server = const Value.absent(),
    this.userId = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.rowId = const Value.absent(),
    required int server,
    required String userId,
  })  : server = Value(server),
        userId = Value(userId);
  static Insertable<Account> custom({
    Expression<int>? rowId,
    Expression<int>? server,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (server != null) 'server': server,
      if (userId != null) 'user_id': userId,
    });
  }

  AccountsCompanion copyWith(
      {Value<int>? rowId, Value<int>? server, Value<String>? userId}) {
    return AccountsCompanion(
      rowId: rowId ?? this.rowId,
      server: server ?? this.server,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (server.present) {
      map['server'] = Variable<int>(server.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('server: $server, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int?> rowId = GeneratedColumn<int?>(
      'row_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<int?> server = GeneratedColumn<int?>(
      'server', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES servers (row_id) ON DELETE CASCADE');
  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String?> userId = GeneratedColumn<String?>(
      'user_id', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [rowId, server, userId];
  @override
  String get aliasedName => _alias ?? 'accounts';
  @override
  String get actualTableName => 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('server')) {
      context.handle(_serverMeta,
          server.isAcceptableOrUnknown(data['server']!, _serverMeta));
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {server, userId},
      ];
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Account.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class File extends DataClass implements Insertable<File> {
  final int rowId;
  final int server;
  final int fileId;
  final int? contentLength;
  final String? contentType;
  final String? etag;
  final DateTime? lastModified;
  final bool? isCollection;
  final int? usedBytes;
  final bool? hasPreview;
  final String? ownerId;
  final String? ownerDisplayName;
  File(
      {required this.rowId,
      required this.server,
      required this.fileId,
      this.contentLength,
      this.contentType,
      this.etag,
      this.lastModified,
      this.isCollection,
      this.usedBytes,
      this.hasPreview,
      this.ownerId,
      this.ownerDisplayName});
  factory File.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return File(
      rowId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}row_id'])!,
      server: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}server'])!,
      fileId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}file_id'])!,
      contentLength: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content_length']),
      contentType: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}content_type']),
      etag: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}etag']),
      lastModified: $FilesTable.$converter0.mapToDart(const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}last_modified'])),
      isCollection: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_collection']),
      usedBytes: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}used_bytes']),
      hasPreview: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}has_preview']),
      ownerId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}owner_id']),
      ownerDisplayName: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}owner_display_name']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['server'] = Variable<int>(server);
    map['file_id'] = Variable<int>(fileId);
    if (!nullToAbsent || contentLength != null) {
      map['content_length'] = Variable<int?>(contentLength);
    }
    if (!nullToAbsent || contentType != null) {
      map['content_type'] = Variable<String?>(contentType);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String?>(etag);
    }
    if (!nullToAbsent || lastModified != null) {
      final converter = $FilesTable.$converter0;
      map['last_modified'] =
          Variable<DateTime?>(converter.mapToSql(lastModified));
    }
    if (!nullToAbsent || isCollection != null) {
      map['is_collection'] = Variable<bool?>(isCollection);
    }
    if (!nullToAbsent || usedBytes != null) {
      map['used_bytes'] = Variable<int?>(usedBytes);
    }
    if (!nullToAbsent || hasPreview != null) {
      map['has_preview'] = Variable<bool?>(hasPreview);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String?>(ownerId);
    }
    if (!nullToAbsent || ownerDisplayName != null) {
      map['owner_display_name'] = Variable<String?>(ownerDisplayName);
    }
    return map;
  }

  FilesCompanion toCompanion(bool nullToAbsent) {
    return FilesCompanion(
      rowId: Value(rowId),
      server: Value(server),
      fileId: Value(fileId),
      contentLength: contentLength == null && nullToAbsent
          ? const Value.absent()
          : Value(contentLength),
      contentType: contentType == null && nullToAbsent
          ? const Value.absent()
          : Value(contentType),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      isCollection: isCollection == null && nullToAbsent
          ? const Value.absent()
          : Value(isCollection),
      usedBytes: usedBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(usedBytes),
      hasPreview: hasPreview == null && nullToAbsent
          ? const Value.absent()
          : Value(hasPreview),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      ownerDisplayName: ownerDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerDisplayName),
    );
  }

  factory File.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return File(
      rowId: serializer.fromJson<int>(json['rowId']),
      server: serializer.fromJson<int>(json['server']),
      fileId: serializer.fromJson<int>(json['fileId']),
      contentLength: serializer.fromJson<int?>(json['contentLength']),
      contentType: serializer.fromJson<String?>(json['contentType']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastModified: serializer.fromJson<DateTime?>(json['lastModified']),
      isCollection: serializer.fromJson<bool?>(json['isCollection']),
      usedBytes: serializer.fromJson<int?>(json['usedBytes']),
      hasPreview: serializer.fromJson<bool?>(json['hasPreview']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      ownerDisplayName: serializer.fromJson<String?>(json['ownerDisplayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'server': serializer.toJson<int>(server),
      'fileId': serializer.toJson<int>(fileId),
      'contentLength': serializer.toJson<int?>(contentLength),
      'contentType': serializer.toJson<String?>(contentType),
      'etag': serializer.toJson<String?>(etag),
      'lastModified': serializer.toJson<DateTime?>(lastModified),
      'isCollection': serializer.toJson<bool?>(isCollection),
      'usedBytes': serializer.toJson<int?>(usedBytes),
      'hasPreview': serializer.toJson<bool?>(hasPreview),
      'ownerId': serializer.toJson<String?>(ownerId),
      'ownerDisplayName': serializer.toJson<String?>(ownerDisplayName),
    };
  }

  File copyWith(
          {int? rowId,
          int? server,
          int? fileId,
          Value<int?> contentLength = const Value.absent(),
          Value<String?> contentType = const Value.absent(),
          Value<String?> etag = const Value.absent(),
          Value<DateTime?> lastModified = const Value.absent(),
          Value<bool?> isCollection = const Value.absent(),
          Value<int?> usedBytes = const Value.absent(),
          Value<bool?> hasPreview = const Value.absent(),
          Value<String?> ownerId = const Value.absent(),
          Value<String?> ownerDisplayName = const Value.absent()}) =>
      File(
        rowId: rowId ?? this.rowId,
        server: server ?? this.server,
        fileId: fileId ?? this.fileId,
        contentLength:
            contentLength.present ? contentLength.value : this.contentLength,
        contentType: contentType.present ? contentType.value : this.contentType,
        etag: etag.present ? etag.value : this.etag,
        lastModified:
            lastModified.present ? lastModified.value : this.lastModified,
        isCollection:
            isCollection.present ? isCollection.value : this.isCollection,
        usedBytes: usedBytes.present ? usedBytes.value : this.usedBytes,
        hasPreview: hasPreview.present ? hasPreview.value : this.hasPreview,
        ownerId: ownerId.present ? ownerId.value : this.ownerId,
        ownerDisplayName: ownerDisplayName.present
            ? ownerDisplayName.value
            : this.ownerDisplayName,
      );
  @override
  String toString() {
    return (StringBuffer('File(')
          ..write('rowId: $rowId, ')
          ..write('server: $server, ')
          ..write('fileId: $fileId, ')
          ..write('contentLength: $contentLength, ')
          ..write('contentType: $contentType, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('isCollection: $isCollection, ')
          ..write('usedBytes: $usedBytes, ')
          ..write('hasPreview: $hasPreview, ')
          ..write('ownerId: $ownerId, ')
          ..write('ownerDisplayName: $ownerDisplayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      rowId,
      server,
      fileId,
      contentLength,
      contentType,
      etag,
      lastModified,
      isCollection,
      usedBytes,
      hasPreview,
      ownerId,
      ownerDisplayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is File &&
          other.rowId == this.rowId &&
          other.server == this.server &&
          other.fileId == this.fileId &&
          other.contentLength == this.contentLength &&
          other.contentType == this.contentType &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified &&
          other.isCollection == this.isCollection &&
          other.usedBytes == this.usedBytes &&
          other.hasPreview == this.hasPreview &&
          other.ownerId == this.ownerId &&
          other.ownerDisplayName == this.ownerDisplayName);
}

class FilesCompanion extends UpdateCompanion<File> {
  final Value<int> rowId;
  final Value<int> server;
  final Value<int> fileId;
  final Value<int?> contentLength;
  final Value<String?> contentType;
  final Value<String?> etag;
  final Value<DateTime?> lastModified;
  final Value<bool?> isCollection;
  final Value<int?> usedBytes;
  final Value<bool?> hasPreview;
  final Value<String?> ownerId;
  final Value<String?> ownerDisplayName;
  const FilesCompanion({
    this.rowId = const Value.absent(),
    this.server = const Value.absent(),
    this.fileId = const Value.absent(),
    this.contentLength = const Value.absent(),
    this.contentType = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isCollection = const Value.absent(),
    this.usedBytes = const Value.absent(),
    this.hasPreview = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.ownerDisplayName = const Value.absent(),
  });
  FilesCompanion.insert({
    this.rowId = const Value.absent(),
    required int server,
    required int fileId,
    this.contentLength = const Value.absent(),
    this.contentType = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.isCollection = const Value.absent(),
    this.usedBytes = const Value.absent(),
    this.hasPreview = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.ownerDisplayName = const Value.absent(),
  })  : server = Value(server),
        fileId = Value(fileId);
  static Insertable<File> custom({
    Expression<int>? rowId,
    Expression<int>? server,
    Expression<int>? fileId,
    Expression<int?>? contentLength,
    Expression<String?>? contentType,
    Expression<String?>? etag,
    Expression<DateTime?>? lastModified,
    Expression<bool?>? isCollection,
    Expression<int?>? usedBytes,
    Expression<bool?>? hasPreview,
    Expression<String?>? ownerId,
    Expression<String?>? ownerDisplayName,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (server != null) 'server': server,
      if (fileId != null) 'file_id': fileId,
      if (contentLength != null) 'content_length': contentLength,
      if (contentType != null) 'content_type': contentType,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (isCollection != null) 'is_collection': isCollection,
      if (usedBytes != null) 'used_bytes': usedBytes,
      if (hasPreview != null) 'has_preview': hasPreview,
      if (ownerId != null) 'owner_id': ownerId,
      if (ownerDisplayName != null) 'owner_display_name': ownerDisplayName,
    });
  }

  FilesCompanion copyWith(
      {Value<int>? rowId,
      Value<int>? server,
      Value<int>? fileId,
      Value<int?>? contentLength,
      Value<String?>? contentType,
      Value<String?>? etag,
      Value<DateTime?>? lastModified,
      Value<bool?>? isCollection,
      Value<int?>? usedBytes,
      Value<bool?>? hasPreview,
      Value<String?>? ownerId,
      Value<String?>? ownerDisplayName}) {
    return FilesCompanion(
      rowId: rowId ?? this.rowId,
      server: server ?? this.server,
      fileId: fileId ?? this.fileId,
      contentLength: contentLength ?? this.contentLength,
      contentType: contentType ?? this.contentType,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      isCollection: isCollection ?? this.isCollection,
      usedBytes: usedBytes ?? this.usedBytes,
      hasPreview: hasPreview ?? this.hasPreview,
      ownerId: ownerId ?? this.ownerId,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (server.present) {
      map['server'] = Variable<int>(server.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<int>(fileId.value);
    }
    if (contentLength.present) {
      map['content_length'] = Variable<int?>(contentLength.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String?>(contentType.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String?>(etag.value);
    }
    if (lastModified.present) {
      final converter = $FilesTable.$converter0;
      map['last_modified'] =
          Variable<DateTime?>(converter.mapToSql(lastModified.value));
    }
    if (isCollection.present) {
      map['is_collection'] = Variable<bool?>(isCollection.value);
    }
    if (usedBytes.present) {
      map['used_bytes'] = Variable<int?>(usedBytes.value);
    }
    if (hasPreview.present) {
      map['has_preview'] = Variable<bool?>(hasPreview.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String?>(ownerId.value);
    }
    if (ownerDisplayName.present) {
      map['owner_display_name'] = Variable<String?>(ownerDisplayName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilesCompanion(')
          ..write('rowId: $rowId, ')
          ..write('server: $server, ')
          ..write('fileId: $fileId, ')
          ..write('contentLength: $contentLength, ')
          ..write('contentType: $contentType, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('isCollection: $isCollection, ')
          ..write('usedBytes: $usedBytes, ')
          ..write('hasPreview: $hasPreview, ')
          ..write('ownerId: $ownerId, ')
          ..write('ownerDisplayName: $ownerDisplayName')
          ..write(')'))
        .toString();
  }
}

class $FilesTable extends Files with TableInfo<$FilesTable, File> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int?> rowId = GeneratedColumn<int?>(
      'row_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<int?> server = GeneratedColumn<int?>(
      'server', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES servers (row_id) ON DELETE CASCADE');
  final VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<int?> fileId = GeneratedColumn<int?>(
      'file_id', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _contentLengthMeta =
      const VerificationMeta('contentLength');
  @override
  late final GeneratedColumn<int?> contentLength = GeneratedColumn<int?>(
      'content_length', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String?> contentType = GeneratedColumn<String?>(
      'content_type', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String?> etag = GeneratedColumn<String?>(
      'etag', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?>
      lastModified = GeneratedColumn<DateTime?>(
              'last_modified', aliasedName, true,
              type: const IntType(), requiredDuringInsert: false)
          .withConverter<DateTime>($FilesTable.$converter0);
  final VerificationMeta _isCollectionMeta =
      const VerificationMeta('isCollection');
  @override
  late final GeneratedColumn<bool?> isCollection = GeneratedColumn<bool?>(
      'is_collection', aliasedName, true,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (is_collection IN (0, 1))');
  final VerificationMeta _usedBytesMeta = const VerificationMeta('usedBytes');
  @override
  late final GeneratedColumn<int?> usedBytes = GeneratedColumn<int?>(
      'used_bytes', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _hasPreviewMeta = const VerificationMeta('hasPreview');
  @override
  late final GeneratedColumn<bool?> hasPreview = GeneratedColumn<bool?>(
      'has_preview', aliasedName, true,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (has_preview IN (0, 1))');
  final VerificationMeta _ownerIdMeta = const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String?> ownerId = GeneratedColumn<String?>(
      'owner_id', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _ownerDisplayNameMeta =
      const VerificationMeta('ownerDisplayName');
  @override
  late final GeneratedColumn<String?> ownerDisplayName =
      GeneratedColumn<String?>('owner_display_name', aliasedName, true,
          type: const StringType(), requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        rowId,
        server,
        fileId,
        contentLength,
        contentType,
        etag,
        lastModified,
        isCollection,
        usedBytes,
        hasPreview,
        ownerId,
        ownerDisplayName
      ];
  @override
  String get aliasedName => _alias ?? 'files';
  @override
  String get actualTableName => 'files';
  @override
  VerificationContext validateIntegrity(Insertable<File> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('server')) {
      context.handle(_serverMeta,
          server.isAcceptableOrUnknown(data['server']!, _serverMeta));
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(_fileIdMeta,
          fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta));
    } else if (isInserting) {
      context.missing(_fileIdMeta);
    }
    if (data.containsKey('content_length')) {
      context.handle(
          _contentLengthMeta,
          contentLength.isAcceptableOrUnknown(
              data['content_length']!, _contentLengthMeta));
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    }
    if (data.containsKey('etag')) {
      context.handle(
          _etagMeta, etag.isAcceptableOrUnknown(data['etag']!, _etagMeta));
    }
    context.handle(_lastModifiedMeta, const VerificationResult.success());
    if (data.containsKey('is_collection')) {
      context.handle(
          _isCollectionMeta,
          isCollection.isAcceptableOrUnknown(
              data['is_collection']!, _isCollectionMeta));
    }
    if (data.containsKey('used_bytes')) {
      context.handle(_usedBytesMeta,
          usedBytes.isAcceptableOrUnknown(data['used_bytes']!, _usedBytesMeta));
    }
    if (data.containsKey('has_preview')) {
      context.handle(
          _hasPreviewMeta,
          hasPreview.isAcceptableOrUnknown(
              data['has_preview']!, _hasPreviewMeta));
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    }
    if (data.containsKey('owner_display_name')) {
      context.handle(
          _ownerDisplayNameMeta,
          ownerDisplayName.isAcceptableOrUnknown(
              data['owner_display_name']!, _ownerDisplayNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {server, fileId},
      ];
  @override
  File map(Map<String, dynamic> data, {String? tablePrefix}) {
    return File.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $FilesTable createAlias(String alias) {
    return $FilesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converter0 =
      const SqliteDateTimeConverter();
}

class AccountFile extends DataClass implements Insertable<AccountFile> {
  final int rowId;
  final int account;
  final int file;
  final String relativePath;
  final bool? isFavorite;
  final bool? isArchived;
  final DateTime? overrideDateTime;
  final DateTime bestDateTime;
  AccountFile(
      {required this.rowId,
      required this.account,
      required this.file,
      required this.relativePath,
      this.isFavorite,
      this.isArchived,
      this.overrideDateTime,
      required this.bestDateTime});
  factory AccountFile.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return AccountFile(
      rowId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}row_id'])!,
      account: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}account'])!,
      file: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}file'])!,
      relativePath: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}relative_path'])!,
      isFavorite: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_favorite']),
      isArchived: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_archived']),
      overrideDateTime: $AccountFilesTable.$converter0.mapToDart(
          const DateTimeType().mapFromDatabaseResponse(
              data['${effectivePrefix}override_date_time'])),
      bestDateTime: $AccountFilesTable.$converter1.mapToDart(
          const DateTimeType().mapFromDatabaseResponse(
              data['${effectivePrefix}best_date_time']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['account'] = Variable<int>(account);
    map['file'] = Variable<int>(file);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || isFavorite != null) {
      map['is_favorite'] = Variable<bool?>(isFavorite);
    }
    if (!nullToAbsent || isArchived != null) {
      map['is_archived'] = Variable<bool?>(isArchived);
    }
    if (!nullToAbsent || overrideDateTime != null) {
      final converter = $AccountFilesTable.$converter0;
      map['override_date_time'] =
          Variable<DateTime?>(converter.mapToSql(overrideDateTime));
    }
    {
      final converter = $AccountFilesTable.$converter1;
      map['best_date_time'] =
          Variable<DateTime>(converter.mapToSql(bestDateTime)!);
    }
    return map;
  }

  AccountFilesCompanion toCompanion(bool nullToAbsent) {
    return AccountFilesCompanion(
      rowId: Value(rowId),
      account: Value(account),
      file: Value(file),
      relativePath: Value(relativePath),
      isFavorite: isFavorite == null && nullToAbsent
          ? const Value.absent()
          : Value(isFavorite),
      isArchived: isArchived == null && nullToAbsent
          ? const Value.absent()
          : Value(isArchived),
      overrideDateTime: overrideDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideDateTime),
      bestDateTime: Value(bestDateTime),
    );
  }

  factory AccountFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountFile(
      rowId: serializer.fromJson<int>(json['rowId']),
      account: serializer.fromJson<int>(json['account']),
      file: serializer.fromJson<int>(json['file']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      isFavorite: serializer.fromJson<bool?>(json['isFavorite']),
      isArchived: serializer.fromJson<bool?>(json['isArchived']),
      overrideDateTime:
          serializer.fromJson<DateTime?>(json['overrideDateTime']),
      bestDateTime: serializer.fromJson<DateTime>(json['bestDateTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'account': serializer.toJson<int>(account),
      'file': serializer.toJson<int>(file),
      'relativePath': serializer.toJson<String>(relativePath),
      'isFavorite': serializer.toJson<bool?>(isFavorite),
      'isArchived': serializer.toJson<bool?>(isArchived),
      'overrideDateTime': serializer.toJson<DateTime?>(overrideDateTime),
      'bestDateTime': serializer.toJson<DateTime>(bestDateTime),
    };
  }

  AccountFile copyWith(
          {int? rowId,
          int? account,
          int? file,
          String? relativePath,
          Value<bool?> isFavorite = const Value.absent(),
          Value<bool?> isArchived = const Value.absent(),
          Value<DateTime?> overrideDateTime = const Value.absent(),
          DateTime? bestDateTime}) =>
      AccountFile(
        rowId: rowId ?? this.rowId,
        account: account ?? this.account,
        file: file ?? this.file,
        relativePath: relativePath ?? this.relativePath,
        isFavorite: isFavorite.present ? isFavorite.value : this.isFavorite,
        isArchived: isArchived.present ? isArchived.value : this.isArchived,
        overrideDateTime: overrideDateTime.present
            ? overrideDateTime.value
            : this.overrideDateTime,
        bestDateTime: bestDateTime ?? this.bestDateTime,
      );
  @override
  String toString() {
    return (StringBuffer('AccountFile(')
          ..write('rowId: $rowId, ')
          ..write('account: $account, ')
          ..write('file: $file, ')
          ..write('relativePath: $relativePath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('overrideDateTime: $overrideDateTime, ')
          ..write('bestDateTime: $bestDateTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, account, file, relativePath,
      isFavorite, isArchived, overrideDateTime, bestDateTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountFile &&
          other.rowId == this.rowId &&
          other.account == this.account &&
          other.file == this.file &&
          other.relativePath == this.relativePath &&
          other.isFavorite == this.isFavorite &&
          other.isArchived == this.isArchived &&
          other.overrideDateTime == this.overrideDateTime &&
          other.bestDateTime == this.bestDateTime);
}

class AccountFilesCompanion extends UpdateCompanion<AccountFile> {
  final Value<int> rowId;
  final Value<int> account;
  final Value<int> file;
  final Value<String> relativePath;
  final Value<bool?> isFavorite;
  final Value<bool?> isArchived;
  final Value<DateTime?> overrideDateTime;
  final Value<DateTime> bestDateTime;
  const AccountFilesCompanion({
    this.rowId = const Value.absent(),
    this.account = const Value.absent(),
    this.file = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.overrideDateTime = const Value.absent(),
    this.bestDateTime = const Value.absent(),
  });
  AccountFilesCompanion.insert({
    this.rowId = const Value.absent(),
    required int account,
    required int file,
    required String relativePath,
    this.isFavorite = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.overrideDateTime = const Value.absent(),
    required DateTime bestDateTime,
  })  : account = Value(account),
        file = Value(file),
        relativePath = Value(relativePath),
        bestDateTime = Value(bestDateTime);
  static Insertable<AccountFile> custom({
    Expression<int>? rowId,
    Expression<int>? account,
    Expression<int>? file,
    Expression<String>? relativePath,
    Expression<bool?>? isFavorite,
    Expression<bool?>? isArchived,
    Expression<DateTime?>? overrideDateTime,
    Expression<DateTime>? bestDateTime,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (account != null) 'account': account,
      if (file != null) 'file': file,
      if (relativePath != null) 'relative_path': relativePath,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isArchived != null) 'is_archived': isArchived,
      if (overrideDateTime != null) 'override_date_time': overrideDateTime,
      if (bestDateTime != null) 'best_date_time': bestDateTime,
    });
  }

  AccountFilesCompanion copyWith(
      {Value<int>? rowId,
      Value<int>? account,
      Value<int>? file,
      Value<String>? relativePath,
      Value<bool?>? isFavorite,
      Value<bool?>? isArchived,
      Value<DateTime?>? overrideDateTime,
      Value<DateTime>? bestDateTime}) {
    return AccountFilesCompanion(
      rowId: rowId ?? this.rowId,
      account: account ?? this.account,
      file: file ?? this.file,
      relativePath: relativePath ?? this.relativePath,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      overrideDateTime: overrideDateTime ?? this.overrideDateTime,
      bestDateTime: bestDateTime ?? this.bestDateTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (account.present) {
      map['account'] = Variable<int>(account.value);
    }
    if (file.present) {
      map['file'] = Variable<int>(file.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool?>(isFavorite.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool?>(isArchived.value);
    }
    if (overrideDateTime.present) {
      final converter = $AccountFilesTable.$converter0;
      map['override_date_time'] =
          Variable<DateTime?>(converter.mapToSql(overrideDateTime.value));
    }
    if (bestDateTime.present) {
      final converter = $AccountFilesTable.$converter1;
      map['best_date_time'] =
          Variable<DateTime>(converter.mapToSql(bestDateTime.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountFilesCompanion(')
          ..write('rowId: $rowId, ')
          ..write('account: $account, ')
          ..write('file: $file, ')
          ..write('relativePath: $relativePath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isArchived: $isArchived, ')
          ..write('overrideDateTime: $overrideDateTime, ')
          ..write('bestDateTime: $bestDateTime')
          ..write(')'))
        .toString();
  }
}

class $AccountFilesTable extends AccountFiles
    with TableInfo<$AccountFilesTable, AccountFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountFilesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int?> rowId = GeneratedColumn<int?>(
      'row_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _accountMeta = const VerificationMeta('account');
  @override
  late final GeneratedColumn<int?> account = GeneratedColumn<int?>(
      'account', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES accounts (row_id) ON DELETE CASCADE');
  final VerificationMeta _fileMeta = const VerificationMeta('file');
  @override
  late final GeneratedColumn<int?> file = GeneratedColumn<int?>(
      'file', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES files (row_id) ON DELETE CASCADE');
  final VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String?> relativePath = GeneratedColumn<String?>(
      'relative_path', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _isFavoriteMeta = const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool?> isFavorite = GeneratedColumn<bool?>(
      'is_favorite', aliasedName, true,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (is_favorite IN (0, 1))');
  final VerificationMeta _isArchivedMeta = const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool?> isArchived = GeneratedColumn<bool?>(
      'is_archived', aliasedName, true,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (is_archived IN (0, 1))');
  final VerificationMeta _overrideDateTimeMeta =
      const VerificationMeta('overrideDateTime');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?>
      overrideDateTime = GeneratedColumn<DateTime?>(
              'override_date_time', aliasedName, true,
              type: const IntType(), requiredDuringInsert: false)
          .withConverter<DateTime>($AccountFilesTable.$converter0);
  final VerificationMeta _bestDateTimeMeta =
      const VerificationMeta('bestDateTime');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?>
      bestDateTime = GeneratedColumn<DateTime?>(
              'best_date_time', aliasedName, false,
              type: const IntType(), requiredDuringInsert: true)
          .withConverter<DateTime>($AccountFilesTable.$converter1);
  @override
  List<GeneratedColumn> get $columns => [
        rowId,
        account,
        file,
        relativePath,
        isFavorite,
        isArchived,
        overrideDateTime,
        bestDateTime
      ];
  @override
  String get aliasedName => _alias ?? 'account_files';
  @override
  String get actualTableName => 'account_files';
  @override
  VerificationContext validateIntegrity(Insertable<AccountFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('account')) {
      context.handle(_accountMeta,
          account.isAcceptableOrUnknown(data['account']!, _accountMeta));
    } else if (isInserting) {
      context.missing(_accountMeta);
    }
    if (data.containsKey('file')) {
      context.handle(
          _fileMeta, file.isAcceptableOrUnknown(data['file']!, _fileMeta));
    } else if (isInserting) {
      context.missing(_fileMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    context.handle(_overrideDateTimeMeta, const VerificationResult.success());
    context.handle(_bestDateTimeMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {account, file},
      ];
  @override
  AccountFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    return AccountFile.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $AccountFilesTable createAlias(String alias) {
    return $AccountFilesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converter0 =
      const SqliteDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converter1 =
      const SqliteDateTimeConverter();
}

class Image extends DataClass implements Insertable<Image> {
  final int accountFile;
  final DateTime lastUpdated;
  final String? fileEtag;
  final int? width;
  final int? height;
  final String? exifRaw;
  final DateTime? dateTimeOriginal;
  Image(
      {required this.accountFile,
      required this.lastUpdated,
      this.fileEtag,
      this.width,
      this.height,
      this.exifRaw,
      this.dateTimeOriginal});
  factory Image.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Image(
      accountFile: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}account_file'])!,
      lastUpdated: $ImagesTable.$converter0.mapToDart(const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}last_updated']))!,
      fileEtag: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}file_etag']),
      width: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}width']),
      height: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}height']),
      exifRaw: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}exif_raw']),
      dateTimeOriginal: $ImagesTable.$converter1.mapToDart(const DateTimeType()
          .mapFromDatabaseResponse(
              data['${effectivePrefix}date_time_original'])),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_file'] = Variable<int>(accountFile);
    {
      final converter = $ImagesTable.$converter0;
      map['last_updated'] =
          Variable<DateTime>(converter.mapToSql(lastUpdated)!);
    }
    if (!nullToAbsent || fileEtag != null) {
      map['file_etag'] = Variable<String?>(fileEtag);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int?>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int?>(height);
    }
    if (!nullToAbsent || exifRaw != null) {
      map['exif_raw'] = Variable<String?>(exifRaw);
    }
    if (!nullToAbsent || dateTimeOriginal != null) {
      final converter = $ImagesTable.$converter1;
      map['date_time_original'] =
          Variable<DateTime?>(converter.mapToSql(dateTimeOriginal));
    }
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      accountFile: Value(accountFile),
      lastUpdated: Value(lastUpdated),
      fileEtag: fileEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(fileEtag),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      exifRaw: exifRaw == null && nullToAbsent
          ? const Value.absent()
          : Value(exifRaw),
      dateTimeOriginal: dateTimeOriginal == null && nullToAbsent
          ? const Value.absent()
          : Value(dateTimeOriginal),
    );
  }

  factory Image.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Image(
      accountFile: serializer.fromJson<int>(json['accountFile']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
      fileEtag: serializer.fromJson<String?>(json['fileEtag']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      exifRaw: serializer.fromJson<String?>(json['exifRaw']),
      dateTimeOriginal:
          serializer.fromJson<DateTime?>(json['dateTimeOriginal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountFile': serializer.toJson<int>(accountFile),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
      'fileEtag': serializer.toJson<String?>(fileEtag),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'exifRaw': serializer.toJson<String?>(exifRaw),
      'dateTimeOriginal': serializer.toJson<DateTime?>(dateTimeOriginal),
    };
  }

  Image copyWith(
          {int? accountFile,
          DateTime? lastUpdated,
          Value<String?> fileEtag = const Value.absent(),
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<String?> exifRaw = const Value.absent(),
          Value<DateTime?> dateTimeOriginal = const Value.absent()}) =>
      Image(
        accountFile: accountFile ?? this.accountFile,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        fileEtag: fileEtag.present ? fileEtag.value : this.fileEtag,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        exifRaw: exifRaw.present ? exifRaw.value : this.exifRaw,
        dateTimeOriginal: dateTimeOriginal.present
            ? dateTimeOriginal.value
            : this.dateTimeOriginal,
      );
  @override
  String toString() {
    return (StringBuffer('Image(')
          ..write('accountFile: $accountFile, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('fileEtag: $fileEtag, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('exifRaw: $exifRaw, ')
          ..write('dateTimeOriginal: $dateTimeOriginal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountFile, lastUpdated, fileEtag, width,
      height, exifRaw, dateTimeOriginal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Image &&
          other.accountFile == this.accountFile &&
          other.lastUpdated == this.lastUpdated &&
          other.fileEtag == this.fileEtag &&
          other.width == this.width &&
          other.height == this.height &&
          other.exifRaw == this.exifRaw &&
          other.dateTimeOriginal == this.dateTimeOriginal);
}

class ImagesCompanion extends UpdateCompanion<Image> {
  final Value<int> accountFile;
  final Value<DateTime> lastUpdated;
  final Value<String?> fileEtag;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> exifRaw;
  final Value<DateTime?> dateTimeOriginal;
  const ImagesCompanion({
    this.accountFile = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.fileEtag = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.exifRaw = const Value.absent(),
    this.dateTimeOriginal = const Value.absent(),
  });
  ImagesCompanion.insert({
    this.accountFile = const Value.absent(),
    required DateTime lastUpdated,
    this.fileEtag = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.exifRaw = const Value.absent(),
    this.dateTimeOriginal = const Value.absent(),
  }) : lastUpdated = Value(lastUpdated);
  static Insertable<Image> custom({
    Expression<int>? accountFile,
    Expression<DateTime>? lastUpdated,
    Expression<String?>? fileEtag,
    Expression<int?>? width,
    Expression<int?>? height,
    Expression<String?>? exifRaw,
    Expression<DateTime?>? dateTimeOriginal,
  }) {
    return RawValuesInsertable({
      if (accountFile != null) 'account_file': accountFile,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (fileEtag != null) 'file_etag': fileEtag,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (exifRaw != null) 'exif_raw': exifRaw,
      if (dateTimeOriginal != null) 'date_time_original': dateTimeOriginal,
    });
  }

  ImagesCompanion copyWith(
      {Value<int>? accountFile,
      Value<DateTime>? lastUpdated,
      Value<String?>? fileEtag,
      Value<int?>? width,
      Value<int?>? height,
      Value<String?>? exifRaw,
      Value<DateTime?>? dateTimeOriginal}) {
    return ImagesCompanion(
      accountFile: accountFile ?? this.accountFile,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      fileEtag: fileEtag ?? this.fileEtag,
      width: width ?? this.width,
      height: height ?? this.height,
      exifRaw: exifRaw ?? this.exifRaw,
      dateTimeOriginal: dateTimeOriginal ?? this.dateTimeOriginal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountFile.present) {
      map['account_file'] = Variable<int>(accountFile.value);
    }
    if (lastUpdated.present) {
      final converter = $ImagesTable.$converter0;
      map['last_updated'] =
          Variable<DateTime>(converter.mapToSql(lastUpdated.value)!);
    }
    if (fileEtag.present) {
      map['file_etag'] = Variable<String?>(fileEtag.value);
    }
    if (width.present) {
      map['width'] = Variable<int?>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int?>(height.value);
    }
    if (exifRaw.present) {
      map['exif_raw'] = Variable<String?>(exifRaw.value);
    }
    if (dateTimeOriginal.present) {
      final converter = $ImagesTable.$converter1;
      map['date_time_original'] =
          Variable<DateTime?>(converter.mapToSql(dateTimeOriginal.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImagesCompanion(')
          ..write('accountFile: $accountFile, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('fileEtag: $fileEtag, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('exifRaw: $exifRaw, ')
          ..write('dateTimeOriginal: $dateTimeOriginal')
          ..write(')'))
        .toString();
  }
}

class $ImagesTable extends Images with TableInfo<$ImagesTable, Image> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _accountFileMeta =
      const VerificationMeta('accountFile');
  @override
  late final GeneratedColumn<int?> accountFile = GeneratedColumn<int?>(
      'account_file', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints:
          'REFERENCES account_files (row_id) ON DELETE CASCADE');
  final VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?> lastUpdated =
      GeneratedColumn<DateTime?>('last_updated', aliasedName, false,
              type: const IntType(), requiredDuringInsert: true)
          .withConverter<DateTime>($ImagesTable.$converter0);
  final VerificationMeta _fileEtagMeta = const VerificationMeta('fileEtag');
  @override
  late final GeneratedColumn<String?> fileEtag = GeneratedColumn<String?>(
      'file_etag', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int?> width = GeneratedColumn<int?>(
      'width', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int?> height = GeneratedColumn<int?>(
      'height', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _exifRawMeta = const VerificationMeta('exifRaw');
  @override
  late final GeneratedColumn<String?> exifRaw = GeneratedColumn<String?>(
      'exif_raw', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _dateTimeOriginalMeta =
      const VerificationMeta('dateTimeOriginal');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?>
      dateTimeOriginal = GeneratedColumn<DateTime?>(
              'date_time_original', aliasedName, true,
              type: const IntType(), requiredDuringInsert: false)
          .withConverter<DateTime>($ImagesTable.$converter1);
  @override
  List<GeneratedColumn> get $columns => [
        accountFile,
        lastUpdated,
        fileEtag,
        width,
        height,
        exifRaw,
        dateTimeOriginal
      ];
  @override
  String get aliasedName => _alias ?? 'images';
  @override
  String get actualTableName => 'images';
  @override
  VerificationContext validateIntegrity(Insertable<Image> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_file')) {
      context.handle(
          _accountFileMeta,
          accountFile.isAcceptableOrUnknown(
              data['account_file']!, _accountFileMeta));
    }
    context.handle(_lastUpdatedMeta, const VerificationResult.success());
    if (data.containsKey('file_etag')) {
      context.handle(_fileEtagMeta,
          fileEtag.isAcceptableOrUnknown(data['file_etag']!, _fileEtagMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('exif_raw')) {
      context.handle(_exifRawMeta,
          exifRaw.isAcceptableOrUnknown(data['exif_raw']!, _exifRawMeta));
    }
    context.handle(_dateTimeOriginalMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountFile};
  @override
  Image map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Image.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converter0 =
      const SqliteDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converter1 =
      const SqliteDateTimeConverter();
}

class ImageLocation extends DataClass implements Insertable<ImageLocation> {
  final int accountFile;
  final int version;
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? countryCode;
  final String? admin1;
  final String? admin2;
  ImageLocation(
      {required this.accountFile,
      required this.version,
      this.name,
      this.latitude,
      this.longitude,
      this.countryCode,
      this.admin1,
      this.admin2});
  factory ImageLocation.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return ImageLocation(
      accountFile: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}account_file'])!,
      version: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}version'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name']),
      latitude: const RealType()
          .mapFromDatabaseResponse(data['${effectivePrefix}latitude']),
      longitude: const RealType()
          .mapFromDatabaseResponse(data['${effectivePrefix}longitude']),
      countryCode: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}country_code']),
      admin1: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}admin1']),
      admin2: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}admin2']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_file'] = Variable<int>(accountFile);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String?>(name);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double?>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double?>(longitude);
    }
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String?>(countryCode);
    }
    if (!nullToAbsent || admin1 != null) {
      map['admin1'] = Variable<String?>(admin1);
    }
    if (!nullToAbsent || admin2 != null) {
      map['admin2'] = Variable<String?>(admin2);
    }
    return map;
  }

  ImageLocationsCompanion toCompanion(bool nullToAbsent) {
    return ImageLocationsCompanion(
      accountFile: Value(accountFile),
      version: Value(version),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      admin1:
          admin1 == null && nullToAbsent ? const Value.absent() : Value(admin1),
      admin2:
          admin2 == null && nullToAbsent ? const Value.absent() : Value(admin2),
    );
  }

  factory ImageLocation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageLocation(
      accountFile: serializer.fromJson<int>(json['accountFile']),
      version: serializer.fromJson<int>(json['version']),
      name: serializer.fromJson<String?>(json['name']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      admin1: serializer.fromJson<String?>(json['admin1']),
      admin2: serializer.fromJson<String?>(json['admin2']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountFile': serializer.toJson<int>(accountFile),
      'version': serializer.toJson<int>(version),
      'name': serializer.toJson<String?>(name),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'countryCode': serializer.toJson<String?>(countryCode),
      'admin1': serializer.toJson<String?>(admin1),
      'admin2': serializer.toJson<String?>(admin2),
    };
  }

  ImageLocation copyWith(
          {int? accountFile,
          int? version,
          Value<String?> name = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<String?> countryCode = const Value.absent(),
          Value<String?> admin1 = const Value.absent(),
          Value<String?> admin2 = const Value.absent()}) =>
      ImageLocation(
        accountFile: accountFile ?? this.accountFile,
        version: version ?? this.version,
        name: name.present ? name.value : this.name,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        countryCode: countryCode.present ? countryCode.value : this.countryCode,
        admin1: admin1.present ? admin1.value : this.admin1,
        admin2: admin2.present ? admin2.value : this.admin2,
      );
  @override
  String toString() {
    return (StringBuffer('ImageLocation(')
          ..write('accountFile: $accountFile, ')
          ..write('version: $version, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('countryCode: $countryCode, ')
          ..write('admin1: $admin1, ')
          ..write('admin2: $admin2')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountFile, version, name, latitude,
      longitude, countryCode, admin1, admin2);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageLocation &&
          other.accountFile == this.accountFile &&
          other.version == this.version &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.countryCode == this.countryCode &&
          other.admin1 == this.admin1 &&
          other.admin2 == this.admin2);
}

class ImageLocationsCompanion extends UpdateCompanion<ImageLocation> {
  final Value<int> accountFile;
  final Value<int> version;
  final Value<String?> name;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> countryCode;
  final Value<String?> admin1;
  final Value<String?> admin2;
  const ImageLocationsCompanion({
    this.accountFile = const Value.absent(),
    this.version = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.admin1 = const Value.absent(),
    this.admin2 = const Value.absent(),
  });
  ImageLocationsCompanion.insert({
    this.accountFile = const Value.absent(),
    required int version,
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.admin1 = const Value.absent(),
    this.admin2 = const Value.absent(),
  }) : version = Value(version);
  static Insertable<ImageLocation> custom({
    Expression<int>? accountFile,
    Expression<int>? version,
    Expression<String?>? name,
    Expression<double?>? latitude,
    Expression<double?>? longitude,
    Expression<String?>? countryCode,
    Expression<String?>? admin1,
    Expression<String?>? admin2,
  }) {
    return RawValuesInsertable({
      if (accountFile != null) 'account_file': accountFile,
      if (version != null) 'version': version,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (countryCode != null) 'country_code': countryCode,
      if (admin1 != null) 'admin1': admin1,
      if (admin2 != null) 'admin2': admin2,
    });
  }

  ImageLocationsCompanion copyWith(
      {Value<int>? accountFile,
      Value<int>? version,
      Value<String?>? name,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<String?>? countryCode,
      Value<String?>? admin1,
      Value<String?>? admin2}) {
    return ImageLocationsCompanion(
      accountFile: accountFile ?? this.accountFile,
      version: version ?? this.version,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      countryCode: countryCode ?? this.countryCode,
      admin1: admin1 ?? this.admin1,
      admin2: admin2 ?? this.admin2,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountFile.present) {
      map['account_file'] = Variable<int>(accountFile.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (name.present) {
      map['name'] = Variable<String?>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double?>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double?>(longitude.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String?>(countryCode.value);
    }
    if (admin1.present) {
      map['admin1'] = Variable<String?>(admin1.value);
    }
    if (admin2.present) {
      map['admin2'] = Variable<String?>(admin2.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageLocationsCompanion(')
          ..write('accountFile: $accountFile, ')
          ..write('version: $version, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('countryCode: $countryCode, ')
          ..write('admin1: $admin1, ')
          ..write('admin2: $admin2')
          ..write(')'))
        .toString();
  }
}

class $ImageLocationsTable extends ImageLocations
    with TableInfo<$ImageLocationsTable, ImageLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageLocationsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _accountFileMeta =
      const VerificationMeta('accountFile');
  @override
  late final GeneratedColumn<int?> accountFile = GeneratedColumn<int?>(
      'account_file', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints:
          'REFERENCES account_files (row_id) ON DELETE CASCADE');
  final VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<int?> version = GeneratedColumn<int?>(
      'version', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _latitudeMeta = const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double?> latitude = GeneratedColumn<double?>(
      'latitude', aliasedName, true,
      type: const RealType(), requiredDuringInsert: false);
  final VerificationMeta _longitudeMeta = const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double?> longitude = GeneratedColumn<double?>(
      'longitude', aliasedName, true,
      type: const RealType(), requiredDuringInsert: false);
  final VerificationMeta _countryCodeMeta =
      const VerificationMeta('countryCode');
  @override
  late final GeneratedColumn<String?> countryCode = GeneratedColumn<String?>(
      'country_code', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _admin1Meta = const VerificationMeta('admin1');
  @override
  late final GeneratedColumn<String?> admin1 = GeneratedColumn<String?>(
      'admin1', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _admin2Meta = const VerificationMeta('admin2');
  @override
  late final GeneratedColumn<String?> admin2 = GeneratedColumn<String?>(
      'admin2', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        accountFile,
        version,
        name,
        latitude,
        longitude,
        countryCode,
        admin1,
        admin2
      ];
  @override
  String get aliasedName => _alias ?? 'image_locations';
  @override
  String get actualTableName => 'image_locations';
  @override
  VerificationContext validateIntegrity(Insertable<ImageLocation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_file')) {
      context.handle(
          _accountFileMeta,
          accountFile.isAcceptableOrUnknown(
              data['account_file']!, _accountFileMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('country_code')) {
      context.handle(
          _countryCodeMeta,
          countryCode.isAcceptableOrUnknown(
              data['country_code']!, _countryCodeMeta));
    }
    if (data.containsKey('admin1')) {
      context.handle(_admin1Meta,
          admin1.isAcceptableOrUnknown(data['admin1']!, _admin1Meta));
    }
    if (data.containsKey('admin2')) {
      context.handle(_admin2Meta,
          admin2.isAcceptableOrUnknown(data['admin2']!, _admin2Meta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountFile};
  @override
  ImageLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    return ImageLocation.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $ImageLocationsTable createAlias(String alias) {
    return $ImageLocationsTable(attachedDatabase, alias);
  }
}

class Trash extends DataClass implements Insertable<Trash> {
  final int file;
  final String filename;
  final String originalLocation;
  final DateTime deletionTime;
  Trash(
      {required this.file,
      required this.filename,
      required this.originalLocation,
      required this.deletionTime});
  factory Trash.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Trash(
      file: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}file'])!,
      filename: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}filename'])!,
      originalLocation: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}original_location'])!,
      deletionTime: $TrashesTable.$converter0.mapToDart(const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}deletion_time']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file'] = Variable<int>(file);
    map['filename'] = Variable<String>(filename);
    map['original_location'] = Variable<String>(originalLocation);
    {
      final converter = $TrashesTable.$converter0;
      map['deletion_time'] =
          Variable<DateTime>(converter.mapToSql(deletionTime)!);
    }
    return map;
  }

  TrashesCompanion toCompanion(bool nullToAbsent) {
    return TrashesCompanion(
      file: Value(file),
      filename: Value(filename),
      originalLocation: Value(originalLocation),
      deletionTime: Value(deletionTime),
    );
  }

  factory Trash.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trash(
      file: serializer.fromJson<int>(json['file']),
      filename: serializer.fromJson<String>(json['filename']),
      originalLocation: serializer.fromJson<String>(json['originalLocation']),
      deletionTime: serializer.fromJson<DateTime>(json['deletionTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'file': serializer.toJson<int>(file),
      'filename': serializer.toJson<String>(filename),
      'originalLocation': serializer.toJson<String>(originalLocation),
      'deletionTime': serializer.toJson<DateTime>(deletionTime),
    };
  }

  Trash copyWith(
          {int? file,
          String? filename,
          String? originalLocation,
          DateTime? deletionTime}) =>
      Trash(
        file: file ?? this.file,
        filename: filename ?? this.filename,
        originalLocation: originalLocation ?? this.originalLocation,
        deletionTime: deletionTime ?? this.deletionTime,
      );
  @override
  String toString() {
    return (StringBuffer('Trash(')
          ..write('file: $file, ')
          ..write('filename: $filename, ')
          ..write('originalLocation: $originalLocation, ')
          ..write('deletionTime: $deletionTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(file, filename, originalLocation, deletionTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trash &&
          other.file == this.file &&
          other.filename == this.filename &&
          other.originalLocation == this.originalLocation &&
          other.deletionTime == this.deletionTime);
}

class TrashesCompanion extends UpdateCompanion<Trash> {
  final Value<int> file;
  final Value<String> filename;
  final Value<String> originalLocation;
  final Value<DateTime> deletionTime;
  const TrashesCompanion({
    this.file = const Value.absent(),
    this.filename = const Value.absent(),
    this.originalLocation = const Value.absent(),
    this.deletionTime = const Value.absent(),
  });
  TrashesCompanion.insert({
    this.file = const Value.absent(),
    required String filename,
    required String originalLocation,
    required DateTime deletionTime,
  })  : filename = Value(filename),
        originalLocation = Value(originalLocation),
        deletionTime = Value(deletionTime);
  static Insertable<Trash> custom({
    Expression<int>? file,
    Expression<String>? filename,
    Expression<String>? originalLocation,
    Expression<DateTime>? deletionTime,
  }) {
    return RawValuesInsertable({
      if (file != null) 'file': file,
      if (filename != null) 'filename': filename,
      if (originalLocation != null) 'original_location': originalLocation,
      if (deletionTime != null) 'deletion_time': deletionTime,
    });
  }

  TrashesCompanion copyWith(
      {Value<int>? file,
      Value<String>? filename,
      Value<String>? originalLocation,
      Value<DateTime>? deletionTime}) {
    return TrashesCompanion(
      file: file ?? this.file,
      filename: filename ?? this.filename,
      originalLocation: originalLocation ?? this.originalLocation,
      deletionTime: deletionTime ?? this.deletionTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (file.present) {
      map['file'] = Variable<int>(file.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (originalLocation.present) {
      map['original_location'] = Variable<String>(originalLocation.value);
    }
    if (deletionTime.present) {
      final converter = $TrashesTable.$converter0;
      map['deletion_time'] =
          Variable<DateTime>(converter.mapToSql(deletionTime.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrashesCompanion(')
          ..write('file: $file, ')
          ..write('filename: $filename, ')
          ..write('originalLocation: $originalLocation, ')
          ..write('deletionTime: $deletionTime')
          ..write(')'))
        .toString();
  }
}

class $TrashesTable extends Trashes with TableInfo<$TrashesTable, Trash> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrashesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _fileMeta = const VerificationMeta('file');
  @override
  late final GeneratedColumn<int?> file = GeneratedColumn<int?>(
      'file', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'REFERENCES files (row_id) ON DELETE CASCADE');
  final VerificationMeta _filenameMeta = const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String?> filename = GeneratedColumn<String?>(
      'filename', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _originalLocationMeta =
      const VerificationMeta('originalLocation');
  @override
  late final GeneratedColumn<String?> originalLocation =
      GeneratedColumn<String?>('original_location', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _deletionTimeMeta =
      const VerificationMeta('deletionTime');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?>
      deletionTime = GeneratedColumn<DateTime?>(
              'deletion_time', aliasedName, false,
              type: const IntType(), requiredDuringInsert: true)
          .withConverter<DateTime>($TrashesTable.$converter0);
  @override
  List<GeneratedColumn> get $columns =>
      [file, filename, originalLocation, deletionTime];
  @override
  String get aliasedName => _alias ?? 'trashes';
  @override
  String get actualTableName => 'trashes';
  @override
  VerificationContext validateIntegrity(Insertable<Trash> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file')) {
      context.handle(
          _fileMeta, file.isAcceptableOrUnknown(data['file']!, _fileMeta));
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('original_location')) {
      context.handle(
          _originalLocationMeta,
          originalLocation.isAcceptableOrUnknown(
              data['original_location']!, _originalLocationMeta));
    } else if (isInserting) {
      context.missing(_originalLocationMeta);
    }
    context.handle(_deletionTimeMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {file};
  @override
  Trash map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Trash.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $TrashesTable createAlias(String alias) {
    return $TrashesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converter0 =
      const SqliteDateTimeConverter();
}

class DirFile extends DataClass implements Insertable<DirFile> {
  final int dir;
  final int child;
  DirFile({required this.dir, required this.child});
  factory DirFile.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return DirFile(
      dir: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}dir'])!,
      child: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}child'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dir'] = Variable<int>(dir);
    map['child'] = Variable<int>(child);
    return map;
  }

  DirFilesCompanion toCompanion(bool nullToAbsent) {
    return DirFilesCompanion(
      dir: Value(dir),
      child: Value(child),
    );
  }

  factory DirFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DirFile(
      dir: serializer.fromJson<int>(json['dir']),
      child: serializer.fromJson<int>(json['child']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dir': serializer.toJson<int>(dir),
      'child': serializer.toJson<int>(child),
    };
  }

  DirFile copyWith({int? dir, int? child}) => DirFile(
        dir: dir ?? this.dir,
        child: child ?? this.child,
      );
  @override
  String toString() {
    return (StringBuffer('DirFile(')
          ..write('dir: $dir, ')
          ..write('child: $child')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dir, child);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DirFile && other.dir == this.dir && other.child == this.child);
}

class DirFilesCompanion extends UpdateCompanion<DirFile> {
  final Value<int> dir;
  final Value<int> child;
  const DirFilesCompanion({
    this.dir = const Value.absent(),
    this.child = const Value.absent(),
  });
  DirFilesCompanion.insert({
    required int dir,
    required int child,
  })  : dir = Value(dir),
        child = Value(child);
  static Insertable<DirFile> custom({
    Expression<int>? dir,
    Expression<int>? child,
  }) {
    return RawValuesInsertable({
      if (dir != null) 'dir': dir,
      if (child != null) 'child': child,
    });
  }

  DirFilesCompanion copyWith({Value<int>? dir, Value<int>? child}) {
    return DirFilesCompanion(
      dir: dir ?? this.dir,
      child: child ?? this.child,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dir.present) {
      map['dir'] = Variable<int>(dir.value);
    }
    if (child.present) {
      map['child'] = Variable<int>(child.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DirFilesCompanion(')
          ..write('dir: $dir, ')
          ..write('child: $child')
          ..write(')'))
        .toString();
  }
}

class $DirFilesTable extends DirFiles with TableInfo<$DirFilesTable, DirFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DirFilesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _dirMeta = const VerificationMeta('dir');
  @override
  late final GeneratedColumn<int?> dir = GeneratedColumn<int?>(
      'dir', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES files (row_id) ON DELETE CASCADE');
  final VerificationMeta _childMeta = const VerificationMeta('child');
  @override
  late final GeneratedColumn<int?> child = GeneratedColumn<int?>(
      'child', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES files (row_id) ON DELETE CASCADE');
  @override
  List<GeneratedColumn> get $columns => [dir, child];
  @override
  String get aliasedName => _alias ?? 'dir_files';
  @override
  String get actualTableName => 'dir_files';
  @override
  VerificationContext validateIntegrity(Insertable<DirFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dir')) {
      context.handle(
          _dirMeta, dir.isAcceptableOrUnknown(data['dir']!, _dirMeta));
    } else if (isInserting) {
      context.missing(_dirMeta);
    }
    if (data.containsKey('child')) {
      context.handle(
          _childMeta, child.isAcceptableOrUnknown(data['child']!, _childMeta));
    } else if (isInserting) {
      context.missing(_childMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dir, child};
  @override
  DirFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    return DirFile.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $DirFilesTable createAlias(String alias) {
    return $DirFilesTable(attachedDatabase, alias);
  }
}

class Album extends DataClass implements Insertable<Album> {
  final int rowId;
  final int file;
  final String? fileEtag;
  final int version;
  final DateTime lastUpdated;
  final String name;
  final String providerType;
  final String providerContent;
  final String coverProviderType;
  final String coverProviderContent;
  final String sortProviderType;
  final String sortProviderContent;
  Album(
      {required this.rowId,
      required this.file,
      this.fileEtag,
      required this.version,
      required this.lastUpdated,
      required this.name,
      required this.providerType,
      required this.providerContent,
      required this.coverProviderType,
      required this.coverProviderContent,
      required this.sortProviderType,
      required this.sortProviderContent});
  factory Album.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Album(
      rowId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}row_id'])!,
      file: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}file'])!,
      fileEtag: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}file_etag']),
      version: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}version'])!,
      lastUpdated: $AlbumsTable.$converter0.mapToDart(const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}last_updated']))!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      providerType: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}provider_type'])!,
      providerContent: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}provider_content'])!,
      coverProviderType: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}cover_provider_type'])!,
      coverProviderContent: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}cover_provider_content'])!,
      sortProviderType: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}sort_provider_type'])!,
      sortProviderContent: const StringType().mapFromDatabaseResponse(
          data['${effectivePrefix}sort_provider_content'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['file'] = Variable<int>(file);
    if (!nullToAbsent || fileEtag != null) {
      map['file_etag'] = Variable<String?>(fileEtag);
    }
    map['version'] = Variable<int>(version);
    {
      final converter = $AlbumsTable.$converter0;
      map['last_updated'] =
          Variable<DateTime>(converter.mapToSql(lastUpdated)!);
    }
    map['name'] = Variable<String>(name);
    map['provider_type'] = Variable<String>(providerType);
    map['provider_content'] = Variable<String>(providerContent);
    map['cover_provider_type'] = Variable<String>(coverProviderType);
    map['cover_provider_content'] = Variable<String>(coverProviderContent);
    map['sort_provider_type'] = Variable<String>(sortProviderType);
    map['sort_provider_content'] = Variable<String>(sortProviderContent);
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      rowId: Value(rowId),
      file: Value(file),
      fileEtag: fileEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(fileEtag),
      version: Value(version),
      lastUpdated: Value(lastUpdated),
      name: Value(name),
      providerType: Value(providerType),
      providerContent: Value(providerContent),
      coverProviderType: Value(coverProviderType),
      coverProviderContent: Value(coverProviderContent),
      sortProviderType: Value(sortProviderType),
      sortProviderContent: Value(sortProviderContent),
    );
  }

  factory Album.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      rowId: serializer.fromJson<int>(json['rowId']),
      file: serializer.fromJson<int>(json['file']),
      fileEtag: serializer.fromJson<String?>(json['fileEtag']),
      version: serializer.fromJson<int>(json['version']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
      name: serializer.fromJson<String>(json['name']),
      providerType: serializer.fromJson<String>(json['providerType']),
      providerContent: serializer.fromJson<String>(json['providerContent']),
      coverProviderType: serializer.fromJson<String>(json['coverProviderType']),
      coverProviderContent:
          serializer.fromJson<String>(json['coverProviderContent']),
      sortProviderType: serializer.fromJson<String>(json['sortProviderType']),
      sortProviderContent:
          serializer.fromJson<String>(json['sortProviderContent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'file': serializer.toJson<int>(file),
      'fileEtag': serializer.toJson<String?>(fileEtag),
      'version': serializer.toJson<int>(version),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
      'name': serializer.toJson<String>(name),
      'providerType': serializer.toJson<String>(providerType),
      'providerContent': serializer.toJson<String>(providerContent),
      'coverProviderType': serializer.toJson<String>(coverProviderType),
      'coverProviderContent': serializer.toJson<String>(coverProviderContent),
      'sortProviderType': serializer.toJson<String>(sortProviderType),
      'sortProviderContent': serializer.toJson<String>(sortProviderContent),
    };
  }

  Album copyWith(
          {int? rowId,
          int? file,
          Value<String?> fileEtag = const Value.absent(),
          int? version,
          DateTime? lastUpdated,
          String? name,
          String? providerType,
          String? providerContent,
          String? coverProviderType,
          String? coverProviderContent,
          String? sortProviderType,
          String? sortProviderContent}) =>
      Album(
        rowId: rowId ?? this.rowId,
        file: file ?? this.file,
        fileEtag: fileEtag.present ? fileEtag.value : this.fileEtag,
        version: version ?? this.version,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        name: name ?? this.name,
        providerType: providerType ?? this.providerType,
        providerContent: providerContent ?? this.providerContent,
        coverProviderType: coverProviderType ?? this.coverProviderType,
        coverProviderContent: coverProviderContent ?? this.coverProviderContent,
        sortProviderType: sortProviderType ?? this.sortProviderType,
        sortProviderContent: sortProviderContent ?? this.sortProviderContent,
      );
  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('rowId: $rowId, ')
          ..write('file: $file, ')
          ..write('fileEtag: $fileEtag, ')
          ..write('version: $version, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('name: $name, ')
          ..write('providerType: $providerType, ')
          ..write('providerContent: $providerContent, ')
          ..write('coverProviderType: $coverProviderType, ')
          ..write('coverProviderContent: $coverProviderContent, ')
          ..write('sortProviderType: $sortProviderType, ')
          ..write('sortProviderContent: $sortProviderContent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      rowId,
      file,
      fileEtag,
      version,
      lastUpdated,
      name,
      providerType,
      providerContent,
      coverProviderType,
      coverProviderContent,
      sortProviderType,
      sortProviderContent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.rowId == this.rowId &&
          other.file == this.file &&
          other.fileEtag == this.fileEtag &&
          other.version == this.version &&
          other.lastUpdated == this.lastUpdated &&
          other.name == this.name &&
          other.providerType == this.providerType &&
          other.providerContent == this.providerContent &&
          other.coverProviderType == this.coverProviderType &&
          other.coverProviderContent == this.coverProviderContent &&
          other.sortProviderType == this.sortProviderType &&
          other.sortProviderContent == this.sortProviderContent);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<int> rowId;
  final Value<int> file;
  final Value<String?> fileEtag;
  final Value<int> version;
  final Value<DateTime> lastUpdated;
  final Value<String> name;
  final Value<String> providerType;
  final Value<String> providerContent;
  final Value<String> coverProviderType;
  final Value<String> coverProviderContent;
  final Value<String> sortProviderType;
  final Value<String> sortProviderContent;
  const AlbumsCompanion({
    this.rowId = const Value.absent(),
    this.file = const Value.absent(),
    this.fileEtag = const Value.absent(),
    this.version = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.name = const Value.absent(),
    this.providerType = const Value.absent(),
    this.providerContent = const Value.absent(),
    this.coverProviderType = const Value.absent(),
    this.coverProviderContent = const Value.absent(),
    this.sortProviderType = const Value.absent(),
    this.sortProviderContent = const Value.absent(),
  });
  AlbumsCompanion.insert({
    this.rowId = const Value.absent(),
    required int file,
    this.fileEtag = const Value.absent(),
    required int version,
    required DateTime lastUpdated,
    required String name,
    required String providerType,
    required String providerContent,
    required String coverProviderType,
    required String coverProviderContent,
    required String sortProviderType,
    required String sortProviderContent,
  })  : file = Value(file),
        version = Value(version),
        lastUpdated = Value(lastUpdated),
        name = Value(name),
        providerType = Value(providerType),
        providerContent = Value(providerContent),
        coverProviderType = Value(coverProviderType),
        coverProviderContent = Value(coverProviderContent),
        sortProviderType = Value(sortProviderType),
        sortProviderContent = Value(sortProviderContent);
  static Insertable<Album> custom({
    Expression<int>? rowId,
    Expression<int>? file,
    Expression<String?>? fileEtag,
    Expression<int>? version,
    Expression<DateTime>? lastUpdated,
    Expression<String>? name,
    Expression<String>? providerType,
    Expression<String>? providerContent,
    Expression<String>? coverProviderType,
    Expression<String>? coverProviderContent,
    Expression<String>? sortProviderType,
    Expression<String>? sortProviderContent,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (file != null) 'file': file,
      if (fileEtag != null) 'file_etag': fileEtag,
      if (version != null) 'version': version,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (name != null) 'name': name,
      if (providerType != null) 'provider_type': providerType,
      if (providerContent != null) 'provider_content': providerContent,
      if (coverProviderType != null) 'cover_provider_type': coverProviderType,
      if (coverProviderContent != null)
        'cover_provider_content': coverProviderContent,
      if (sortProviderType != null) 'sort_provider_type': sortProviderType,
      if (sortProviderContent != null)
        'sort_provider_content': sortProviderContent,
    });
  }

  AlbumsCompanion copyWith(
      {Value<int>? rowId,
      Value<int>? file,
      Value<String?>? fileEtag,
      Value<int>? version,
      Value<DateTime>? lastUpdated,
      Value<String>? name,
      Value<String>? providerType,
      Value<String>? providerContent,
      Value<String>? coverProviderType,
      Value<String>? coverProviderContent,
      Value<String>? sortProviderType,
      Value<String>? sortProviderContent}) {
    return AlbumsCompanion(
      rowId: rowId ?? this.rowId,
      file: file ?? this.file,
      fileEtag: fileEtag ?? this.fileEtag,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      name: name ?? this.name,
      providerType: providerType ?? this.providerType,
      providerContent: providerContent ?? this.providerContent,
      coverProviderType: coverProviderType ?? this.coverProviderType,
      coverProviderContent: coverProviderContent ?? this.coverProviderContent,
      sortProviderType: sortProviderType ?? this.sortProviderType,
      sortProviderContent: sortProviderContent ?? this.sortProviderContent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (file.present) {
      map['file'] = Variable<int>(file.value);
    }
    if (fileEtag.present) {
      map['file_etag'] = Variable<String?>(fileEtag.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (lastUpdated.present) {
      final converter = $AlbumsTable.$converter0;
      map['last_updated'] =
          Variable<DateTime>(converter.mapToSql(lastUpdated.value)!);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (providerType.present) {
      map['provider_type'] = Variable<String>(providerType.value);
    }
    if (providerContent.present) {
      map['provider_content'] = Variable<String>(providerContent.value);
    }
    if (coverProviderType.present) {
      map['cover_provider_type'] = Variable<String>(coverProviderType.value);
    }
    if (coverProviderContent.present) {
      map['cover_provider_content'] =
          Variable<String>(coverProviderContent.value);
    }
    if (sortProviderType.present) {
      map['sort_provider_type'] = Variable<String>(sortProviderType.value);
    }
    if (sortProviderContent.present) {
      map['sort_provider_content'] =
          Variable<String>(sortProviderContent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('file: $file, ')
          ..write('fileEtag: $fileEtag, ')
          ..write('version: $version, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('name: $name, ')
          ..write('providerType: $providerType, ')
          ..write('providerContent: $providerContent, ')
          ..write('coverProviderType: $coverProviderType, ')
          ..write('coverProviderContent: $coverProviderContent, ')
          ..write('sortProviderType: $sortProviderType, ')
          ..write('sortProviderContent: $sortProviderContent')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int?> rowId = GeneratedColumn<int?>(
      'row_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _fileMeta = const VerificationMeta('file');
  @override
  late final GeneratedColumn<int?> file = GeneratedColumn<int?>(
      'file', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'UNIQUE REFERENCES files (row_id) ON DELETE CASCADE');
  final VerificationMeta _fileEtagMeta = const VerificationMeta('fileEtag');
  @override
  late final GeneratedColumn<String?> fileEtag = GeneratedColumn<String?>(
      'file_etag', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<int?> version = GeneratedColumn<int?>(
      'version', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _lastUpdatedMeta =
      const VerificationMeta('lastUpdated');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?> lastUpdated =
      GeneratedColumn<DateTime?>('last_updated', aliasedName, false,
              type: const IntType(), requiredDuringInsert: true)
          .withConverter<DateTime>($AlbumsTable.$converter0);
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _providerTypeMeta =
      const VerificationMeta('providerType');
  @override
  late final GeneratedColumn<String?> providerType = GeneratedColumn<String?>(
      'provider_type', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _providerContentMeta =
      const VerificationMeta('providerContent');
  @override
  late final GeneratedColumn<String?> providerContent =
      GeneratedColumn<String?>('provider_content', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _coverProviderTypeMeta =
      const VerificationMeta('coverProviderType');
  @override
  late final GeneratedColumn<String?> coverProviderType =
      GeneratedColumn<String?>('cover_provider_type', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _coverProviderContentMeta =
      const VerificationMeta('coverProviderContent');
  @override
  late final GeneratedColumn<String?> coverProviderContent =
      GeneratedColumn<String?>('cover_provider_content', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _sortProviderTypeMeta =
      const VerificationMeta('sortProviderType');
  @override
  late final GeneratedColumn<String?> sortProviderType =
      GeneratedColumn<String?>('sort_provider_type', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _sortProviderContentMeta =
      const VerificationMeta('sortProviderContent');
  @override
  late final GeneratedColumn<String?> sortProviderContent =
      GeneratedColumn<String?>('sort_provider_content', aliasedName, false,
          type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        rowId,
        file,
        fileEtag,
        version,
        lastUpdated,
        name,
        providerType,
        providerContent,
        coverProviderType,
        coverProviderContent,
        sortProviderType,
        sortProviderContent
      ];
  @override
  String get aliasedName => _alias ?? 'albums';
  @override
  String get actualTableName => 'albums';
  @override
  VerificationContext validateIntegrity(Insertable<Album> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('file')) {
      context.handle(
          _fileMeta, file.isAcceptableOrUnknown(data['file']!, _fileMeta));
    } else if (isInserting) {
      context.missing(_fileMeta);
    }
    if (data.containsKey('file_etag')) {
      context.handle(_fileEtagMeta,
          fileEtag.isAcceptableOrUnknown(data['file_etag']!, _fileEtagMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    context.handle(_lastUpdatedMeta, const VerificationResult.success());
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('provider_type')) {
      context.handle(
          _providerTypeMeta,
          providerType.isAcceptableOrUnknown(
              data['provider_type']!, _providerTypeMeta));
    } else if (isInserting) {
      context.missing(_providerTypeMeta);
    }
    if (data.containsKey('provider_content')) {
      context.handle(
          _providerContentMeta,
          providerContent.isAcceptableOrUnknown(
              data['provider_content']!, _providerContentMeta));
    } else if (isInserting) {
      context.missing(_providerContentMeta);
    }
    if (data.containsKey('cover_provider_type')) {
      context.handle(
          _coverProviderTypeMeta,
          coverProviderType.isAcceptableOrUnknown(
              data['cover_provider_type']!, _coverProviderTypeMeta));
    } else if (isInserting) {
      context.missing(_coverProviderTypeMeta);
    }
    if (data.containsKey('cover_provider_content')) {
      context.handle(
          _coverProviderContentMeta,
          coverProviderContent.isAcceptableOrUnknown(
              data['cover_provider_content']!, _coverProviderContentMeta));
    } else if (isInserting) {
      context.missing(_coverProviderContentMeta);
    }
    if (data.containsKey('sort_provider_type')) {
      context.handle(
          _sortProviderTypeMeta,
          sortProviderType.isAcceptableOrUnknown(
              data['sort_provider_type']!, _sortProviderTypeMeta));
    } else if (isInserting) {
      context.missing(_sortProviderTypeMeta);
    }
    if (data.containsKey('sort_provider_content')) {
      context.handle(
          _sortProviderContentMeta,
          sortProviderContent.isAcceptableOrUnknown(
              data['sort_provider_content']!, _sortProviderContentMeta));
    } else if (isInserting) {
      context.missing(_sortProviderContentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Album.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converter0 =
      const SqliteDateTimeConverter();
}

class AlbumShare extends DataClass implements Insertable<AlbumShare> {
  final int album;
  final String userId;
  final String? displayName;
  final DateTime sharedAt;
  AlbumShare(
      {required this.album,
      required this.userId,
      this.displayName,
      required this.sharedAt});
  factory AlbumShare.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return AlbumShare(
      album: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}album'])!,
      userId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user_id'])!,
      displayName: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}display_name']),
      sharedAt: $AlbumSharesTable.$converter0.mapToDart(const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}shared_at']))!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['album'] = Variable<int>(album);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String?>(displayName);
    }
    {
      final converter = $AlbumSharesTable.$converter0;
      map['shared_at'] = Variable<DateTime>(converter.mapToSql(sharedAt)!);
    }
    return map;
  }

  AlbumSharesCompanion toCompanion(bool nullToAbsent) {
    return AlbumSharesCompanion(
      album: Value(album),
      userId: Value(userId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      sharedAt: Value(sharedAt),
    );
  }

  factory AlbumShare.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumShare(
      album: serializer.fromJson<int>(json['album']),
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      sharedAt: serializer.fromJson<DateTime>(json['sharedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'album': serializer.toJson<int>(album),
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String?>(displayName),
      'sharedAt': serializer.toJson<DateTime>(sharedAt),
    };
  }

  AlbumShare copyWith(
          {int? album,
          String? userId,
          Value<String?> displayName = const Value.absent(),
          DateTime? sharedAt}) =>
      AlbumShare(
        album: album ?? this.album,
        userId: userId ?? this.userId,
        displayName: displayName.present ? displayName.value : this.displayName,
        sharedAt: sharedAt ?? this.sharedAt,
      );
  @override
  String toString() {
    return (StringBuffer('AlbumShare(')
          ..write('album: $album, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('sharedAt: $sharedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(album, userId, displayName, sharedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumShare &&
          other.album == this.album &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.sharedAt == this.sharedAt);
}

class AlbumSharesCompanion extends UpdateCompanion<AlbumShare> {
  final Value<int> album;
  final Value<String> userId;
  final Value<String?> displayName;
  final Value<DateTime> sharedAt;
  const AlbumSharesCompanion({
    this.album = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sharedAt = const Value.absent(),
  });
  AlbumSharesCompanion.insert({
    required int album,
    required String userId,
    this.displayName = const Value.absent(),
    required DateTime sharedAt,
  })  : album = Value(album),
        userId = Value(userId),
        sharedAt = Value(sharedAt);
  static Insertable<AlbumShare> custom({
    Expression<int>? album,
    Expression<String>? userId,
    Expression<String?>? displayName,
    Expression<DateTime>? sharedAt,
  }) {
    return RawValuesInsertable({
      if (album != null) 'album': album,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (sharedAt != null) 'shared_at': sharedAt,
    });
  }

  AlbumSharesCompanion copyWith(
      {Value<int>? album,
      Value<String>? userId,
      Value<String?>? displayName,
      Value<DateTime>? sharedAt}) {
    return AlbumSharesCompanion(
      album: album ?? this.album,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (album.present) {
      map['album'] = Variable<int>(album.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String?>(displayName.value);
    }
    if (sharedAt.present) {
      final converter = $AlbumSharesTable.$converter0;
      map['shared_at'] =
          Variable<DateTime>(converter.mapToSql(sharedAt.value)!);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumSharesCompanion(')
          ..write('album: $album, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('sharedAt: $sharedAt')
          ..write(')'))
        .toString();
  }
}

class $AlbumSharesTable extends AlbumShares
    with TableInfo<$AlbumSharesTable, AlbumShare> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumSharesTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<int?> album = GeneratedColumn<int?>(
      'album', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES albums (row_id) ON DELETE CASCADE');
  final VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String?> userId = GeneratedColumn<String?>(
      'user_id', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String?> displayName = GeneratedColumn<String?>(
      'display_name', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _sharedAtMeta = const VerificationMeta('sharedAt');
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime?> sharedAt =
      GeneratedColumn<DateTime?>('shared_at', aliasedName, false,
              type: const IntType(), requiredDuringInsert: true)
          .withConverter<DateTime>($AlbumSharesTable.$converter0);
  @override
  List<GeneratedColumn> get $columns => [album, userId, displayName, sharedAt];
  @override
  String get aliasedName => _alias ?? 'album_shares';
  @override
  String get actualTableName => 'album_shares';
  @override
  VerificationContext validateIntegrity(Insertable<AlbumShare> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('album')) {
      context.handle(
          _albumMeta, album.isAcceptableOrUnknown(data['album']!, _albumMeta));
    } else if (isInserting) {
      context.missing(_albumMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    context.handle(_sharedAtMeta, const VerificationResult.success());
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {album, userId};
  @override
  AlbumShare map(Map<String, dynamic> data, {String? tablePrefix}) {
    return AlbumShare.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $AlbumSharesTable createAlias(String alias) {
    return $AlbumSharesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converter0 =
      const SqliteDateTimeConverter();
}

class Tag extends DataClass implements Insertable<Tag> {
  final int rowId;
  final int server;
  final int tagId;
  final String displayName;
  final bool? userVisible;
  final bool? userAssignable;
  Tag(
      {required this.rowId,
      required this.server,
      required this.tagId,
      required this.displayName,
      this.userVisible,
      this.userAssignable});
  factory Tag.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Tag(
      rowId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}row_id'])!,
      server: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}server'])!,
      tagId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}tag_id'])!,
      displayName: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}display_name'])!,
      userVisible: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user_visible']),
      userAssignable: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}user_assignable']),
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['server'] = Variable<int>(server);
    map['tag_id'] = Variable<int>(tagId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || userVisible != null) {
      map['user_visible'] = Variable<bool?>(userVisible);
    }
    if (!nullToAbsent || userAssignable != null) {
      map['user_assignable'] = Variable<bool?>(userAssignable);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      rowId: Value(rowId),
      server: Value(server),
      tagId: Value(tagId),
      displayName: Value(displayName),
      userVisible: userVisible == null && nullToAbsent
          ? const Value.absent()
          : Value(userVisible),
      userAssignable: userAssignable == null && nullToAbsent
          ? const Value.absent()
          : Value(userAssignable),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      rowId: serializer.fromJson<int>(json['rowId']),
      server: serializer.fromJson<int>(json['server']),
      tagId: serializer.fromJson<int>(json['tagId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      userVisible: serializer.fromJson<bool?>(json['userVisible']),
      userAssignable: serializer.fromJson<bool?>(json['userAssignable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'server': serializer.toJson<int>(server),
      'tagId': serializer.toJson<int>(tagId),
      'displayName': serializer.toJson<String>(displayName),
      'userVisible': serializer.toJson<bool?>(userVisible),
      'userAssignable': serializer.toJson<bool?>(userAssignable),
    };
  }

  Tag copyWith(
          {int? rowId,
          int? server,
          int? tagId,
          String? displayName,
          Value<bool?> userVisible = const Value.absent(),
          Value<bool?> userAssignable = const Value.absent()}) =>
      Tag(
        rowId: rowId ?? this.rowId,
        server: server ?? this.server,
        tagId: tagId ?? this.tagId,
        displayName: displayName ?? this.displayName,
        userVisible: userVisible.present ? userVisible.value : this.userVisible,
        userAssignable:
            userAssignable.present ? userAssignable.value : this.userAssignable,
      );
  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('rowId: $rowId, ')
          ..write('server: $server, ')
          ..write('tagId: $tagId, ')
          ..write('displayName: $displayName, ')
          ..write('userVisible: $userVisible, ')
          ..write('userAssignable: $userAssignable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      rowId, server, tagId, displayName, userVisible, userAssignable);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.rowId == this.rowId &&
          other.server == this.server &&
          other.tagId == this.tagId &&
          other.displayName == this.displayName &&
          other.userVisible == this.userVisible &&
          other.userAssignable == this.userAssignable);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> rowId;
  final Value<int> server;
  final Value<int> tagId;
  final Value<String> displayName;
  final Value<bool?> userVisible;
  final Value<bool?> userAssignable;
  const TagsCompanion({
    this.rowId = const Value.absent(),
    this.server = const Value.absent(),
    this.tagId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.userVisible = const Value.absent(),
    this.userAssignable = const Value.absent(),
  });
  TagsCompanion.insert({
    this.rowId = const Value.absent(),
    required int server,
    required int tagId,
    required String displayName,
    this.userVisible = const Value.absent(),
    this.userAssignable = const Value.absent(),
  })  : server = Value(server),
        tagId = Value(tagId),
        displayName = Value(displayName);
  static Insertable<Tag> custom({
    Expression<int>? rowId,
    Expression<int>? server,
    Expression<int>? tagId,
    Expression<String>? displayName,
    Expression<bool?>? userVisible,
    Expression<bool?>? userAssignable,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (server != null) 'server': server,
      if (tagId != null) 'tag_id': tagId,
      if (displayName != null) 'display_name': displayName,
      if (userVisible != null) 'user_visible': userVisible,
      if (userAssignable != null) 'user_assignable': userAssignable,
    });
  }

  TagsCompanion copyWith(
      {Value<int>? rowId,
      Value<int>? server,
      Value<int>? tagId,
      Value<String>? displayName,
      Value<bool?>? userVisible,
      Value<bool?>? userAssignable}) {
    return TagsCompanion(
      rowId: rowId ?? this.rowId,
      server: server ?? this.server,
      tagId: tagId ?? this.tagId,
      displayName: displayName ?? this.displayName,
      userVisible: userVisible ?? this.userVisible,
      userAssignable: userAssignable ?? this.userAssignable,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (server.present) {
      map['server'] = Variable<int>(server.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (userVisible.present) {
      map['user_visible'] = Variable<bool?>(userVisible.value);
    }
    if (userAssignable.present) {
      map['user_assignable'] = Variable<bool?>(userAssignable.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('server: $server, ')
          ..write('tagId: $tagId, ')
          ..write('displayName: $displayName, ')
          ..write('userVisible: $userVisible, ')
          ..write('userAssignable: $userAssignable')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int?> rowId = GeneratedColumn<int?>(
      'row_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<int?> server = GeneratedColumn<int?>(
      'server', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES servers (row_id) ON DELETE CASCADE');
  final VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int?> tagId = GeneratedColumn<int?>(
      'tag_id', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String?> displayName = GeneratedColumn<String?>(
      'display_name', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _userVisibleMeta =
      const VerificationMeta('userVisible');
  @override
  late final GeneratedColumn<bool?> userVisible = GeneratedColumn<bool?>(
      'user_visible', aliasedName, true,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (user_visible IN (0, 1))');
  final VerificationMeta _userAssignableMeta =
      const VerificationMeta('userAssignable');
  @override
  late final GeneratedColumn<bool?> userAssignable = GeneratedColumn<bool?>(
      'user_assignable', aliasedName, true,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (user_assignable IN (0, 1))');
  @override
  List<GeneratedColumn> get $columns =>
      [rowId, server, tagId, displayName, userVisible, userAssignable];
  @override
  String get aliasedName => _alias ?? 'tags';
  @override
  String get actualTableName => 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('server')) {
      context.handle(_serverMeta,
          server.isAcceptableOrUnknown(data['server']!, _serverMeta));
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('user_visible')) {
      context.handle(
          _userVisibleMeta,
          userVisible.isAcceptableOrUnknown(
              data['user_visible']!, _userVisibleMeta));
    }
    if (data.containsKey('user_assignable')) {
      context.handle(
          _userAssignableMeta,
          userAssignable.isAcceptableOrUnknown(
              data['user_assignable']!, _userAssignableMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {server, tagId},
      ];
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Tag.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int rowId;
  final int account;
  final String name;
  final int thumbFaceId;
  final int count;
  Person(
      {required this.rowId,
      required this.account,
      required this.name,
      required this.thumbFaceId,
      required this.count});
  factory Person.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return Person(
      rowId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}row_id'])!,
      account: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}account'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      thumbFaceId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}thumb_face_id'])!,
      count: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}count'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['account'] = Variable<int>(account);
    map['name'] = Variable<String>(name);
    map['thumb_face_id'] = Variable<int>(thumbFaceId);
    map['count'] = Variable<int>(count);
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      rowId: Value(rowId),
      account: Value(account),
      name: Value(name),
      thumbFaceId: Value(thumbFaceId),
      count: Value(count),
    );
  }

  factory Person.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      rowId: serializer.fromJson<int>(json['rowId']),
      account: serializer.fromJson<int>(json['account']),
      name: serializer.fromJson<String>(json['name']),
      thumbFaceId: serializer.fromJson<int>(json['thumbFaceId']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'account': serializer.toJson<int>(account),
      'name': serializer.toJson<String>(name),
      'thumbFaceId': serializer.toJson<int>(thumbFaceId),
      'count': serializer.toJson<int>(count),
    };
  }

  Person copyWith(
          {int? rowId,
          int? account,
          String? name,
          int? thumbFaceId,
          int? count}) =>
      Person(
        rowId: rowId ?? this.rowId,
        account: account ?? this.account,
        name: name ?? this.name,
        thumbFaceId: thumbFaceId ?? this.thumbFaceId,
        count: count ?? this.count,
      );
  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('rowId: $rowId, ')
          ..write('account: $account, ')
          ..write('name: $name, ')
          ..write('thumbFaceId: $thumbFaceId, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, account, name, thumbFaceId, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.rowId == this.rowId &&
          other.account == this.account &&
          other.name == this.name &&
          other.thumbFaceId == this.thumbFaceId &&
          other.count == this.count);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<int> rowId;
  final Value<int> account;
  final Value<String> name;
  final Value<int> thumbFaceId;
  final Value<int> count;
  const PersonsCompanion({
    this.rowId = const Value.absent(),
    this.account = const Value.absent(),
    this.name = const Value.absent(),
    this.thumbFaceId = const Value.absent(),
    this.count = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.rowId = const Value.absent(),
    required int account,
    required String name,
    required int thumbFaceId,
    required int count,
  })  : account = Value(account),
        name = Value(name),
        thumbFaceId = Value(thumbFaceId),
        count = Value(count);
  static Insertable<Person> custom({
    Expression<int>? rowId,
    Expression<int>? account,
    Expression<String>? name,
    Expression<int>? thumbFaceId,
    Expression<int>? count,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (account != null) 'account': account,
      if (name != null) 'name': name,
      if (thumbFaceId != null) 'thumb_face_id': thumbFaceId,
      if (count != null) 'count': count,
    });
  }

  PersonsCompanion copyWith(
      {Value<int>? rowId,
      Value<int>? account,
      Value<String>? name,
      Value<int>? thumbFaceId,
      Value<int>? count}) {
    return PersonsCompanion(
      rowId: rowId ?? this.rowId,
      account: account ?? this.account,
      name: name ?? this.name,
      thumbFaceId: thumbFaceId ?? this.thumbFaceId,
      count: count ?? this.count,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (account.present) {
      map['account'] = Variable<int>(account.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (thumbFaceId.present) {
      map['thumb_face_id'] = Variable<int>(thumbFaceId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('rowId: $rowId, ')
          ..write('account: $account, ')
          ..write('name: $name, ')
          ..write('thumbFaceId: $thumbFaceId, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int?> rowId = GeneratedColumn<int?>(
      'row_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _accountMeta = const VerificationMeta('account');
  @override
  late final GeneratedColumn<int?> account = GeneratedColumn<int?>(
      'account', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      defaultConstraints: 'REFERENCES accounts (row_id) ON DELETE CASCADE');
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _thumbFaceIdMeta =
      const VerificationMeta('thumbFaceId');
  @override
  late final GeneratedColumn<int?> thumbFaceId = GeneratedColumn<int?>(
      'thumb_face_id', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int?> count = GeneratedColumn<int?>(
      'count', aliasedName, false,
      type: const IntType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [rowId, account, name, thumbFaceId, count];
  @override
  String get aliasedName => _alias ?? 'persons';
  @override
  String get actualTableName => 'persons';
  @override
  VerificationContext validateIntegrity(Insertable<Person> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
          _rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    }
    if (data.containsKey('account')) {
      context.handle(_accountMeta,
          account.isAcceptableOrUnknown(data['account']!, _accountMeta));
    } else if (isInserting) {
      context.missing(_accountMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('thumb_face_id')) {
      context.handle(
          _thumbFaceIdMeta,
          thumbFaceId.isAcceptableOrUnknown(
              data['thumb_face_id']!, _thumbFaceIdMeta));
    } else if (isInserting) {
      context.missing(_thumbFaceIdMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
          _countMeta, count.isAcceptableOrUnknown(data['count']!, _countMeta));
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {account, name},
      ];
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    return Person.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

abstract class _$SqliteDb extends GeneratedDatabase {
  _$SqliteDb(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  _$SqliteDb.connect(DatabaseConnection c) : super.connect(c);
  late final $ServersTable servers = $ServersTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $FilesTable files = $FilesTable(this);
  late final $AccountFilesTable accountFiles = $AccountFilesTable(this);
  late final $ImagesTable images = $ImagesTable(this);
  late final $ImageLocationsTable imageLocations = $ImageLocationsTable(this);
  late final $TrashesTable trashes = $TrashesTable(this);
  late final $DirFilesTable dirFiles = $DirFilesTable(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $AlbumSharesTable albumShares = $AlbumSharesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        servers,
        accounts,
        files,
        accountFiles,
        images,
        imageLocations,
        trashes,
        dirFiles,
        albums,
        albumShares,
        tags,
        persons
      ];
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$SqliteDbNpLog on SqliteDb {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("entity.sqlite.database.SqliteDb");
}
