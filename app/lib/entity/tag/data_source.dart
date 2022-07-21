import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:xml/xml.dart';

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
          canAssign: 1,
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
              canAssign: 1,
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

  static final _log = Logger("entity.tag.data_source.TagRemoteDataSource");
}
