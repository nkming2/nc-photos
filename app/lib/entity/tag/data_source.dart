import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:xml/xml.dart';

part 'data_source.g.dart';

@npLog
class TagRemoteDataSource implements TagDataSource {
  const TagRemoteDataSource();

  @override
  list(Account account) async {
    _log.info("[list] $account");
    final response = await Api(account).systemtags().propfind(
          id: 1,
          displayName: 1,
          userVisible: 1,
          userAssignable: 1,
        );
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    return WebdavResponseParser().parseTags(xml);
  }

  @override
  listByFile(Account account, File file) async {
    _log.info("[listByFile] ${file.path}");
    final response =
        await Api(account).systemtagsRelations().files(file.fileId!).propfind(
              id: 1,
              displayName: 1,
              userVisible: 1,
              userAssignable: 1,
            );
    if (!response.isGood) {
      _log.severe("[listByFile] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    return WebdavResponseParser().parseTags(xml);
  }
}

@npLog
class TagSqliteDbDataSource implements TagDataSource {
  const TagSqliteDbDataSource(this.sqliteDb);

  @override
  list(Account account) async {
    _log.info("[list] $account");
    final dbTags = await sqliteDb.use((db) async {
      return await db.allTags(appAccount: account);
    });
    return dbTags.convertToAppTag();
  }

  @override
  listByFile(Account account, File file) async {
    _log.info("[listByFile] ${file.path}");
    throw UnimplementedError();
  }

  final sql.SqliteDb sqliteDb;
}
