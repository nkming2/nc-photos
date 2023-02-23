import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/entity_converter.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/np_api_util.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_codegen/np_codegen.dart';

part 'data_source.g.dart';

@npLog
class FaceRemoteDataSource implements FaceDataSource {
  const FaceRemoteDataSource();

  @override
  list(Account account, Person person) async {
    _log.info("[list] $person");
    final response = await ApiUtil.fromAccount(account)
        .ocs()
        .facerecognition()
        .person(person.name)
        .faces()
        .get();
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }

    final apiFaces = await api.FaceParser().parse(response.body);
    return apiFaces.map(ApiFaceConverter.fromApi).toList();
  }
}
