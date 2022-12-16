import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/type.dart';
import 'package:np_codegen/np_codegen.dart';

part 'data_source.g.dart';

@npLog
class FaceRemoteDataSource implements FaceDataSource {
  const FaceRemoteDataSource();

  @override
  list(Account account, Person person) async {
    _log.info("[list] $person");
    final response = await Api(account)
        .ocs()
        .facerecognition()
        .person(person.name)
        .faces()
        .get();
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }

    final json = jsonDecode(response.body);
    final List<JsonObj> dataJson = json["ocs"]["data"].cast<JsonObj>();
    return _FaceParser().parseList(dataJson);
  }
}

@npLog
class _FaceParser {
  List<Face> parseList(List<JsonObj> jsons) {
    final product = <Face>[];
    for (final j in jsons) {
      try {
        product.add(parseSingle(j));
      } catch (e) {
        _log.severe("[parseList] Failed parsing json: ${jsonEncode(j)}", e);
      }
    }
    return product;
  }

  Face parseSingle(JsonObj json) {
    return Face(
      id: json["id"],
      fileId: json["fileId"],
    );
  }
}
