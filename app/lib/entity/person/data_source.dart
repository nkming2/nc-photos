import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/entity_converter.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/np_api_util.dart';
import 'package:np_api/np_api.dart' as api;
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/type.dart';

part 'data_source.g.dart';

@npLog
class PersonRemoteDataSource implements PersonDataSource {
  const PersonRemoteDataSource();

  @override
  list(Account account) async {
    _log.info("[list] $account");
    final response = await ApiUtil.fromAccount(account)
        .ocs()
        .facerecognition()
        .persons()
        .get();
    if (!response.isGood) {
      _log.severe("[list] Failed requesting server: $response");
      throw ApiException(
        response: response,
        message: "Server responed with an error: HTTP ${response.statusCode}",
      );
    }

    final apiPersons = await api.PersonParser().parse(response.body);
    return apiPersons.map(ApiPersonConverter.fromApi).toList();
  }
}

@npLog
class PersonSqliteDbDataSource implements PersonDataSource {
  const PersonSqliteDbDataSource(this.sqliteDb);

  @override
  list(Account account) async {
    _log.info("[list] $account");
    final dbPersons = await sqliteDb.use((db) async {
      return await db.allPersons(appAccount: account);
    });
    return dbPersons.convertToAppPerson();
  }

  final sql.SqliteDb sqliteDb;
}

@npLog
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
}
