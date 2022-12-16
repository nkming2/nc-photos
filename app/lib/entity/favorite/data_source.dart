import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:xml/xml.dart';

part 'data_source.g.dart';

@npLog
class FavoriteRemoteDataSource implements FavoriteDataSource {
  const FavoriteRemoteDataSource();

  @override
  list(Account account, File dir) async {
    _log.info("[list] ${dir.path}");
    final response = await Api(account).files().report(
          path: dir.path,
          favorite: true,
        );
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    return WebdavResponseParser().parseFavorites(xml);
  }
}
