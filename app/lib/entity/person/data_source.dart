import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/type.dart';

class PersonRemoteDataSource implements PersonDataSource {
  const PersonRemoteDataSource();

  @override
  list(Account account) async {
    _log.info("[list] $account");
    final response = await Api(account).ocs().facerecognition().persons().get();
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message:
              "Server responed with an error: HTTP ${response.statusCode}");
    }

    final json = jsonDecode(response.body);
    final List<JsonObj> dataJson = json["ocs"]["data"].cast<JsonObj>();
    return _PersonParser().parseList(dataJson);
  }

  static final _log =
      Logger("entity.person.data_source.PersonRemoteDataSource");
}

class _PersonParser {
  List<Person> parseList(List<JsonObj> jsons) {
    final product = <Person>[];
    for (final j in jsons) {
      try {
        product.add(parseSingle(j));
      } catch (e) {
        _log.severe("[parseList] Failed parsing json: ${jsonEncode(j)}", e);
      }
    }
    return product;
  }

  Person parseSingle(JsonObj json) {
    return Person(
      name: json["name"],
      thumbFaceId: json["thumbFaceId"],
      count: json["count"],
    );
  }

  static final _log = Logger("entity.person.data_source._PersonParser");
}
