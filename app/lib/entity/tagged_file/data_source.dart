import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/tagged_file.dart';
import 'package:nc_photos/entity/webdav_response_parser.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:xml/xml.dart';

part 'data_source.g.dart';

@npLog
class TaggedFileRemoteDataSource implements TaggedFileDataSource {
  const TaggedFileRemoteDataSource();

  @override
  list(Account account, File dir, List<Tag> tags) async {
    _log.info(
        "[list] ${tags.map((t) => t.displayName).toReadableString()} under ${dir.path}");
    final response = await Api(account).files().report(
          path: dir.path,
          systemtag: tags.map((t) => t.id).toList(),
        );
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }

    final xml = XmlDocument.parse(response.body);
    return WebdavResponseParser().parseTaggedFiles(xml);
  }
}
