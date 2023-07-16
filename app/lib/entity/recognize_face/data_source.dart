import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/entity_converter.dart';
import 'package:nc_photos/entity/recognize_face.dart';
import 'package:nc_photos/entity/recognize_face/repo.dart';
import 'package:nc_photos/entity/recognize_face_item.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/table.dart';
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/map_extension.dart';
import 'package:nc_photos/np_api_util.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';

part 'data_source.g.dart';

@npLog
class RecognizeFaceRemoteDataSource implements RecognizeFaceDataSource {
  const RecognizeFaceRemoteDataSource();

  @override
  Future<List<RecognizeFace>> getFaces(Account account) async {
    _log.info("[getFaces] account: ${account.userId}");
    final response = await ApiUtil.fromAccount(account)
        .recognize(account.userId.raw)
        .faces()
        .propfind();
    if (!response.isGood) {
      _log.severe("[getFaces] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }

    final apiFaces = await api.RecognizeFaceParser().parse(response.body);
    return apiFaces
        .map(ApiRecognizeFaceConverter.fromApi)
        .where((e) => e.label.isNotEmpty)
        .toList();
  }

  @override
  Future<List<RecognizeFaceItem>> getItems(
      Account account, RecognizeFace face) async {
    _log.info("[getItems] account: ${account.userId}, face: ${face.label}");
    final response = await ApiUtil.fromAccount(account)
        .recognize(account.userId.raw)
        .face(face.label)
        .propfind(
          getcontentlength: 1,
          getcontenttype: 1,
          getetag: 1,
          getlastmodified: 1,
          faceDetections: 1,
          fileMetadataSize: 1,
          hasPreview: 1,
          realpath: 1,
          favorite: 1,
          fileid: 1,
        );
    if (!response.isGood) {
      _log.severe("[getItems] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }

    final apiItems = await api.RecognizeFaceItemParser().parse(response.body);
    return apiItems
        .where((f) => f.fileId != null)
        .map(ApiRecognizeFaceItemConverter.fromApi)
        .toList();
  }

  @override
  Future<Map<RecognizeFace, List<RecognizeFaceItem>>> getMultiFaceItems(
    Account account,
    List<RecognizeFace> faces, {
    ErrorWithValueHandler<RecognizeFace>? onError,
  }) async {
    final results = await Future.wait(faces.map((f) async {
      try {
        return MapEntry(f, await getItems(account, f));
      } catch (e, stackTrace) {
        _log.severe("[getMultiFaceItems] Failed while querying face: $f", e,
            stackTrace);
        onError?.call(f, e, stackTrace);
        return null;
      }
    }));
    return results.whereNotNull().toMap();
  }

  @override
  Future<Map<RecognizeFace, RecognizeFaceItem>> getMultiFaceLastItems(
    Account account,
    List<RecognizeFace> faces, {
    ErrorWithValueHandler<RecognizeFace>? onError,
  }) async {
    final results = await getMultiFaceItems(account, faces, onError: onError);
    return results
        .map((key, value) => MapEntry(key, maxBy(value, (e) => e.fileId)!));
  }
}

@npLog
class RecognizeFaceSqliteDbDataSource implements RecognizeFaceDataSource {
  const RecognizeFaceSqliteDbDataSource(this.sqliteDb);

  @override
  Future<List<RecognizeFace>> getFaces(Account account) async {
    _log.info("[getFaces] $account");
    final dbFaces = await sqliteDb.use((db) async {
      return await db.allRecognizeFaces(
        account: sql.ByAccount.app(account),
      );
    });
    return dbFaces
        .map((f) {
          try {
            return SqliteRecognizeFaceConverter.fromSql(f);
          } catch (e, stackTrace) {
            _log.severe(
                "[getFaces] Failed while converting DB entry", e, stackTrace);
            return null;
          }
        })
        .whereNotNull()
        .toList();
  }

  @override
  Future<List<RecognizeFaceItem>> getItems(
      Account account, RecognizeFace face) async {
    _log.info("[getItems] $face");
    final results = await getMultiFaceItems(account, [face]);
    return results[face]!;
  }

  @override
  Future<Map<RecognizeFace, List<RecognizeFaceItem>>> getMultiFaceItems(
    Account account,
    List<RecognizeFace> faces, {
    ErrorWithValueHandler<RecognizeFace>? onError,
    List<RecognizeFaceItemSort>? orderBy,
    int? limit,
  }) async {
    _log.info("[getMultiFaceItems] ${faces.toReadableString()}");
    final dbItems = await sqliteDb.use((db) async {
      final results = await Future.wait(faces.map((f) async {
        try {
          return MapEntry(
            f,
            await db.recognizeFaceItemsByParentLabel(
              account: sql.ByAccount.app(account),
              label: f.label,
              orderBy: orderBy?.toOrderingItem(db).toList(),
              limit: limit,
            ),
          );
        } catch (e, stackTrace) {
          onError?.call(f, e, stackTrace);
          return null;
        }
      }));
      return results.whereNotNull().toMap();
    });
    return dbItems.entries
        .map((entry) {
          final face = entry.key;
          try {
            return MapEntry(
              face,
              entry.value
                  .map((i) => SqliteRecognizeFaceItemConverter.fromSql(
                      account.userId.raw, face.label, i))
                  .toList(),
            );
          } catch (e, stackTrace) {
            onError?.call(face, e, stackTrace);
            return null;
          }
        })
        .whereNotNull()
        .toMap();
  }

  @override
  Future<Map<RecognizeFace, RecognizeFaceItem>> getMultiFaceLastItems(
    Account account,
    List<RecognizeFace> faces, {
    ErrorWithValueHandler<RecognizeFace>? onError,
  }) async {
    final results = await getMultiFaceItems(
      account,
      faces,
      onError: onError,
      orderBy: [RecognizeFaceItemSort.fileIdDesc],
      limit: 1,
    );
    return (results..removeWhere((key, value) => value.isEmpty))
        .map((key, value) => MapEntry(key, value.first));
  }

  final sql.SqliteDb sqliteDb;
}
