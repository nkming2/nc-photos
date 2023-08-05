import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/recognize_face.dart';
import 'package:nc_photos/entity/recognize_face_item.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/list_util.dart' as list_util;
import 'package:nc_photos/map_extension.dart';
import 'package:nc_photos/use_case/recognize_face/list_recognize_face.dart';
import 'package:nc_photos/use_case/recognize_face/list_recognize_face_item.dart';
import 'package:np_codegen/np_codegen.dart';

part 'sync_recognize_face.g.dart';

@npLog
class SyncRecognizeFace {
  const SyncRecognizeFace(this._c);

  /// Sync people in cache db with remote server
  ///
  /// Return if any people were updated
  Future<bool> call(Account account) async {
    _log.info("[call] Sync people with remote");
    final faces = await _getFaceResults(account);
    if (faces == null) {
      return false;
    }
    var shouldUpdate = !faces.isEmpty;
    final items =
        await _getFaceItemResults(account, faces.results.values.toList());
    shouldUpdate = shouldUpdate || items.values.any((e) => !e.isEmpty);
    if (!shouldUpdate) {
      return false;
    }

    await _c.sqliteDb.use((db) async {
      final dbAccount = await db.accountOf(account);
      await db.batch((batch) {
        for (final d in faces.deletes) {
          batch.deleteWhere(
            db.recognizeFaces,
            (sql.$RecognizeFacesTable t) =>
                t.account.equals(dbAccount.rowId) & t.label.equals(d),
          );
        }
        for (final u in faces.updates) {
          batch.update(
            db.recognizeFaces,
            sql.RecognizeFacesCompanion(
              label: sql.Value(faces.results[u]!.label),
            ),
            where: (sql.$RecognizeFacesTable t) =>
                t.account.equals(dbAccount.rowId) & t.label.equals(u),
          );
        }
        for (final i in faces.inserts) {
          batch.insert(
            db.recognizeFaces,
            SqliteRecognizeFaceConverter.toSql(dbAccount, faces.results[i]!),
            mode: sql.InsertMode.insertOrIgnore,
          );
        }
      });

      // update each item
      for (final f in faces.results.values) {
        try {
          await _syncDbForFaceItem(db, dbAccount, f, items[f]!);
        } catch (e, stackTrace) {
          _log.shout("[call] Failed to update db for face: $f", e, stackTrace);
        }
      }
    });
    return true;
  }

  Future<_FaceResult?> _getFaceResults(Account account) async {
    int faceSorter(RecognizeFace a, RecognizeFace b) =>
        a.label.compareTo(b.label);
    late final List<RecognizeFace> remote;
    try {
      remote = (await ListRecognizeFace(_c.withRemoteRepo())(account).last)
        ..sort(faceSorter);
    } catch (e) {
      if (e is ApiException && e.response.statusCode == 404) {
        // recognize app probably not installed, ignore
        _log.info("[_getFaceResults] Recognize app not installed");
        return null;
      }
      rethrow;
    }
    final cache = (await ListRecognizeFace(_c.withLocalRepo())(account).last)
      ..sort(faceSorter);
    final diff = list_util.diffWith(cache, remote, faceSorter);
    final inserts = diff.onlyInB;
    _log.info("[_getFaceResults] New face: ${inserts.toReadableString()}");
    final deletes = diff.onlyInA;
    _log.info("[_getFaceResults] Removed face: ${deletes.toReadableString()}");
    final updates = remote.where((r) {
      final c = cache.firstWhereOrNull((c) => c.label == r.label);
      return c != null && c != r;
    }).toList();
    _log.info("[_getFaceResults] Updated face: ${updates.toReadableString()}");
    return _FaceResult(
      results: remote.map((e) => MapEntry(e.label, e)).toMap(),
      inserts: inserts.map((e) => e.label).toList(),
      updates: updates.map((e) => e.label).toList(),
      deletes: deletes.map((e) => e.label).toList(),
    );
  }

  Future<Map<RecognizeFace, _FaceItemResult>> _getFaceItemResults(
      Account account, List<RecognizeFace> faces) async {
    Object? firstError;
    StackTrace? firstStackTrace;
    final remote = await ListMultipleRecognizeFaceItem(_c.withRemoteRepo())(
      account,
      faces,
      onError: (f, e, stackTrace) {
        _log.severe(
          "[_getFaceItemResults] Failed while listing remote face: $f",
          e,
          stackTrace,
        );
        if (firstError == null) {
          firstError = e;
          firstStackTrace = stackTrace;
        }
      },
    ).last;
    if (firstError != null) {
      Error.throwWithStackTrace(
          firstError!, firstStackTrace ?? StackTrace.current);
    }
    final cache = await ListMultipleRecognizeFaceItem(_c.withLocalRepo())(
      account,
      faces,
      onError: (f, e, stackTrace) {
        _log.severe("[_getFaceItemResults] Failed while listing cache face: $f",
            e, stackTrace);
      },
    ).last;

    int itemSorter(RecognizeFaceItem a, RecognizeFaceItem b) =>
        a.fileId.compareTo(b.fileId);
    final results = <RecognizeFace, _FaceItemResult>{};
    for (final f in faces) {
      final thisCache = (cache[f] ?? [])..sort(itemSorter);
      final thisRemote = (remote[f] ?? [])..sort(itemSorter);
      final diff = list_util.diffWith<RecognizeFaceItem>(
          thisCache, thisRemote, itemSorter);
      final inserts = diff.onlyInB;
      _log.info(
          "[_getFaceItemResults] New item: ${inserts.toReadableString()}");
      final deletes = diff.onlyInA;
      _log.info(
          "[_getFaceItemResults] Removed item: ${deletes.toReadableString()}");
      final updates = thisRemote.where((r) {
        final c = thisCache.firstWhereOrNull((c) => c.fileId == r.fileId);
        return c != null && c != r;
      }).toList();
      _log.info(
          "[_getFaceItemResults] Updated item: ${updates.toReadableString()}");
      results[f] = _FaceItemResult(
        results: thisRemote.map((e) => MapEntry(e.fileId, e)).toMap(),
        inserts: inserts.map((e) => e.fileId).toList(),
        updates: updates.map((e) => e.fileId).toList(),
        deletes: deletes.map((e) => e.fileId).toList(),
      );
    }
    return results;
  }

  // Future<_FaceItemResult?> _getFaceItemResults(
  //     Account account, RecognizeFace face) async {
  //   late final List<RecognizeFaceItem> remote;
  //   try {
  //     remote =
  //         await ListRecognizeFaceItem(_c.withRemoteRepo())(account, face).last;
  //   } catch (e) {
  //     if (e is ApiException && e.response.statusCode == 404) {
  //       // recognize app probably not installed, ignore
  //       _log.info("[_getFaceItemResults] Recognize app not installed");
  //       return null;
  //     }
  //     rethrow;
  //   }
  //   final cache =
  //       await ListRecognizeFaceItem(_c.withLocalRepo())(account, face).last;
  //   int itemSorter(RecognizeFaceItem a, RecognizeFaceItem b) =>
  //       a.fileId.compareTo(b.fileId);
  //   final diff = list_util.diffWith(cache, remote, itemSorter);
  //   final inserts = diff.onlyInB;
  //   _log.info("[_getFaceItemResults] New face: ${inserts.toReadableString()}");
  //   final deletes = diff.onlyInA;
  //   _log.info(
  //       "[_getFaceItemResults] Removed face: ${deletes.toReadableString()}");
  //   final updates = remote.where((r) {
  //     final c = cache.firstWhereOrNull((c) => c.fileId == r.fileId);
  //     return c != null && c != r;
  //   }).toList();
  //   _log.info(
  //       "[_getFaceItemResults] Updated face: ${updates.toReadableString()}");
  //   return _FaceItemResult(
  //     results: remote.map((e) => MapEntry(e.fileId, e)).toMap(),
  //     inserts: inserts.map((e) => e.fileId).toList(),
  //     updates: updates.map((e) => e.fileId).toList(),
  //     deletes: deletes.map((e) => e.fileId).toList(),
  //   );
  // }

  Future<void> _syncDbForFaceItem(sql.SqliteDb db, sql.Account dbAccount,
      RecognizeFace face, _FaceItemResult item) async {
    await db.transaction(() async {
      final dbFace = await db.recognizeFaceByLabel(
        account: sql.ByAccount.sql(dbAccount),
        label: face.label,
      );
      await db.batch((batch) {
        for (final d in item.deletes) {
          batch.deleteWhere(
            db.recognizeFaceItems,
            (sql.$RecognizeFaceItemsTable t) =>
                t.parent.equals(dbFace.rowId) & t.fileId.equals(d),
          );
        }
        for (final u in item.updates) {
          batch.update(
            db.recognizeFaceItems,
            SqliteRecognizeFaceItemConverter.toSql(dbFace, item.results[u]!),
            where: (sql.$RecognizeFaceItemsTable t) =>
                t.parent.equals(dbFace.rowId) & t.fileId.equals(u),
          );
        }
        for (final i in item.inserts) {
          batch.insert(
            db.recognizeFaceItems,
            SqliteRecognizeFaceItemConverter.toSql(dbFace, item.results[i]!),
            mode: sql.InsertMode.insertOrIgnore,
          );
        }
      });
    });
  }

  final DiContainer _c;
}

class _FaceResult {
  const _FaceResult({
    required this.results,
    required this.inserts,
    required this.updates,
    required this.deletes,
  });

  bool get isEmpty => inserts.isEmpty && updates.isEmpty && deletes.isEmpty;

  final Map<String, RecognizeFace> results;
  final List<String> inserts;
  final List<String> updates;
  final List<String> deletes;
}

class _FaceItemResult {
  const _FaceItemResult({
    required this.results,
    required this.inserts,
    required this.updates,
    required this.deletes,
  });

  bool get isEmpty => inserts.isEmpty && updates.isEmpty && deletes.isEmpty;

  final Map<int, RecognizeFaceItem> results;
  final List<int> inserts;
  final List<int> updates;
  final List<int> deletes;
}
