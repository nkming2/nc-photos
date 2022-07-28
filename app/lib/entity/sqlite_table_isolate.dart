import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:nc_photos/app_init.dart' as app_init;
import 'package:nc_photos/entity/sqlite_table.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;

typedef ComputeWithDbCallback<T, U> = Future<U> Function(
    SqliteDb db, T message);

/// Create a drift db running in an isolate
///
/// This is only expected to be used in the main isolate
Future<SqliteDb> createDb() async {
  // see: https://drift.simonbinder.eu/docs/advanced-features/isolates/
  final driftIsolate = await _createDriftIsolate();
  final connection = await driftIsolate.connect();
  return SqliteDb.connect(connection);
}

Future<U> computeWithDb<T, U>(
    ComputeWithDbCallback<T, U> callback, T args) async {
  return await compute(
    _computeWithDbImpl<T, U>,
    _ComputeWithDbMessage(
        await platform.getSqliteConnectionArgs(), callback, args),
  );
}

class _IsolateStartRequest {
  const _IsolateStartRequest(this.sendDriftIsolate, this.platformArgs);

  final SendPort sendDriftIsolate;
  final Map<String, dynamic> platformArgs;
}

class _ComputeWithDbMessage<T, U> {
  const _ComputeWithDbMessage(
      this.sqliteConnectionArgs, this.callback, this.args);

  final Map<String, dynamic> sqliteConnectionArgs;
  final ComputeWithDbCallback<T, U> callback;
  final T args;
}

Future<DriftIsolate> _createDriftIsolate() async {
  final args = await platform.getSqliteConnectionArgs();
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, args),
  );
  // _startBackground will send the DriftIsolate to this ReceivePort
  return await receivePort.first as DriftIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  app_init.initDrift();

  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = platform.openSqliteConnectionWithArgs(request.platformArgs);
  // we're using DriftIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used DriftIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final driftIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
    // this breaks background service!
    serialize: false,
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendDriftIsolate.send(driftIsolate);
}

Future<U> _computeWithDbImpl<T, U>(_ComputeWithDbMessage<T, U> message) async {
  app_init.initDrift();

  // we don't use driftIsolate because opening a DB normally is found to perform
  // better
  final sqliteDb = SqliteDb(
    executor:
        platform.openSqliteConnectionWithArgs(message.sqliteConnectionArgs),
  );
  try {
    return await message.callback(sqliteDb, message.args);
  } finally {
    await sqliteDb.close();
  }
}
